---
title: "Mojolicious スパイク調査"
date: 2025-12-16
---

## 要約（短い）

- 概要: Mojolicious は Sebastian Riedel 発案のリアルタイム対応 Perl フレームワークで、WebSocket/SSE、非同期 I/O、Promises、組み込みサーバ（`morbo`/`hypnotoad`）などを標準で備える。
- 主な特徴: `Mojolicious::Lite` による単一ファイルプロトタイプから MVC 構成までの拡張、`Mojo::UserAgent`/`Mojo::IOLoop` 等のツールキット、豊富なプラグイン群。
- 導入: `cpanm Mojolicious`（またはワンライナー）で簡単に導入可能。`perlbrew` 等で隔離推奨。
- 開発とデプロイ: 開発は `morbo`、本番は `hypnotoad`（prefork・ホットデプロイ）や PSGI 経由の運用が一般的。リバースプロキシで TLS 終端を行う。 
- 運用注意: `secrets` の設定、`max_request_size` 等のリソース制限、テンプレートのサニタイズ、信頼できるプロキシ設定を確認する。

## 目的

Perl のウェブフレームワーク `Mojolicious` の技術調査を行い、導入可否、主要概念、導入手順、デプロイ方法、セキュリティ上の注意点、参考資料をまとめる。

## 調査項目（当初）

- 概要と特徴
- インストール方法と必須モジュール
- 主要概念（ルーティング、コントローラ、テンプレート、ヘルパー、プラグイン、非同期I/O）
- 最小サンプル（Hello World / routes + templates）
- デプロイ方法（Hypnotoad, Morbo, PSGI, Docker など）
- セキュリティとパフォーマンス留意点
- 参考資料・チュートリアル・実例リポジトリ

## Investigation Results

- 調査は段階的に行い、このセクションに随時追記する。

### 概要

- `Mojolicious` はリアルタイム機能（WebSocket、非同期 I/O）を持つ軽量でフルスタックな Perl フレームワーク。
- コアは `Mojo` ツールキット（`Mojo::UserAgent`, `Mojo::IOLoop`, `Mojo::Template`, `Mojo::DOM` など）で構成される。

### インストール

- 推奨ワンライナー（cpanminus 経由）:

	`curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious`

- `perlbrew` 等の隔離環境での利用が推奨される。

### 最小サンプル

```
use Mojolicious::Lite;

get '/' => {text => 'I ♥ Mojolicious!'};

app->start;
```

- 開発サーバ: `morbo hello.pl`、本番向け: `hypnotoad`（prefork/zero-downtime をサポート）

### 主要コンポーネント

- ルータ: `->routes` でエンドポイントを定義。
- コントローラ: `Mojolicious::Controller`、アクションは `$c`（コントローラオブジェクト）を受け取る。
- レンダラ: `Mojo::Template` ベースのテンプレート（`.ep`）をサポート。
- セッション/シークレット: `secrets` を設定して署名済みクッキーを利用。
- 非同期: `Mojo::IOLoop`、`Mojo::Promise`、`Mojo::UserAgent` の非同期 API。
- テスト: `Test::Mojo` による HTTP レスポンス検証。

### サーバ / デプロイ

- 開発用: `morbo`（自動リロード）
- 本番用: `hypnotoad`（prefork・ホットデプロイ対応） / `prefork` / `psgi` 経由で Plack 環境へ組み込み可能。
- 生成サポート: `Mojolicious::Command::Author::generate::dockerfile` 等で Dockerfile を生成可能。

### セキュリティと運用上の注意点

- `secrets` を必ず明示的に設定する（デフォルトは安全でない）。
- `max_request_size` 等でリクエストボディサイズ制限を設定し、メモリの暴走を防ぐ。
- テンプレートにユーザ入力を生で埋めない、CSRF 対策（フォーム）や入力バリデーションを行う。

## Deployment & best practices

Summary:
- Mojolicious provides several built-in servers: `morbo` (dev restarter), `daemon` (simple), `prefork` (multi-process) and `hypnotoad` (production pre-fork manager with hot-deploy).
- Common production patterns: run Hypnotoad behind a reverse proxy (Nginx/Apache/Envoy), or containerize with Docker/PSGI (Plack) for cloud-native deployments.

Hypnotoad:
- Start: `hypnotoad ./script/my_app` (daemonizes, defaults to `production`).
- Supports hot deployment (re-run command -> USR2 -> zero-downtime upgrade).
- Key settings via `app->config(hypnotoad => {...})` or `myapp.conf`: `listen`, `workers`, `clients`, `spare`, `accepts`, `graceful_timeout`, `trusted_proxies`, `proxy`.
- Use `proxy => 1` or `MOJO_REVERSE_PROXY=1` when behind proxies so X-Forwarded-* are honored. Configure `trusted_proxies` / `MOJO_TRUSTED_PROXIES` appropriately.
- Manage with systemd (Type=forking) and use provided `pid_file` and `ExecReload` to trigger upgrades.

Prefork / Morbo:
- `prefork` provides pre-fork worker model (`./script/my_app prefork`) and is good for scaling across CPU cores.
- `morbo` is a development restarter; do not use in production.

Containers / Docker:
- Minimal Dockerfile pattern:

```dockerfile
FROM perl
WORKDIR /opt/myapp
COPY . .
RUN cpanm --installdeps -n .
EXPOSE 3000
CMD ./myapp.pl prefork
```
- `mojo generate dockerfile` can scaffold a Dockerfile. Prefer pre-fork (`prefork`) or run Hypnotoad in containers depending on orchestration strategy.

Reverse proxy and TLS:
- Put Nginx/Apache/Envoy in front to terminate TLS and handle WebSocket proxying. Example Nginx proxy settings include `proxy_set_header Upgrade` and `proxy_set_header Connection "upgrade"` for WebSockets.
- Ensure `X-Forwarded-Proto` and `X-Forwarded-For` are passed and enable `MOJO_REVERSE_PROXY` or `proxy => 1` in Hypnotoad.

PSGI / Plack:
- Mojolicious apps can run under PSGI with `plackup` or `Mojo::Server::PSGI`, enabling use of FCGI, uWSGI, mod_perl adapters and Plack middleware.

Operational recommendations:
- Tune `workers` (2x cores for non-blocking apps) and `clients` (lower for blocking workloads).
- Set `graceful_timeout` slightly above max expected request time to allow graceful shutdowns.
- Use `spare` to reduce restart latency during rolling upgrades.
- Use `inactivity_timeout` and `keep_alive_timeout` for resource control.
- Avoid installing custom signal handlers in app code (servers use signals for process control).
- For blocking heavy computations, offload to subprocesses (`Mojo::IOLoop->subprocess`) or external workers (e.g., Minion) to keep event loop responsive.

Security and env vars:
- Do NOT store secrets in code; use configuration and environment variables. `MOJO_HOME` can set app home; `MOJO_REVERSE_PROXY` enables proxy handling.
- Configure `trusted_proxies`/`MOJO_TRUSTED_PROXIES` to restrict which proxies are trusted.
- Use TLS (`listen => ['https://*:443?cert=/path/cert&key=/path/key']`) and secure session secrets (`app->secrets`) properly.

Further reading / next steps:
- Add example `systemd` unit and a sample `Dockerfile` to repository for quickstart (ask before committing).
- Collect community example repos and common Hypnotoad config patterns.

## External resources & further reading

- Official website / Guides: https://mojolicious.org/ — primary documentation and guides (Tutorial, Cookbook, Guides).
- Official docs (API): https://docs.mojolicious.org/ — comprehensive reference (Mojo::IOLoop, Controller, Hypnotoad, etc.).
- GitHub repository: https://github.com/mojolicious/mojo — source, `examples/` directory, issues, discussions and release notes.
- MetaCPAN: https://metacpan.org/search?q=mojolicious — CPAN modules, plugins and distribution metadata.
- Discussions / community: https://github.com/mojolicious/mojo/discussions — community Q&A and announcements (replaces older forum).
- Wiki: https://github.com/mojolicious/mojo/wiki (community-contributed examples and notes).
- Plugins / ecosystem: Search MetaCPAN for `Mojolicious::Plugin::*` (e.g., Minion for jobs, JSONConfig, Mount, Status).
- Tutorials & articles:
	- Official Guides' tutorial and cookbook pages (start here).
	- Community blog posts and Perl Weekly articles (search for "Mojolicious tutorial" or "Mojolicious websocket example").

Notes:
- `examples/` in the GitHub repo contains many ready-to-run snippets (SSE, WebSocket, streaming, proxies).
- Use `mojo generate` subcommands (`app`, `lite-app`, `dockerfile`, `makefile`) to scaffold apps and deployment artifacts.


### 参考ドキュメント（抜粋）

- 公式サイト: https://mojolicious.org/
- ドキュメント/ガイド: https://docs.mojolicious.org/
- API / Pod: https://metacpan.org/pod/Mojolicious


## External Resources

- 公式サイト: https://mojolicious.org/
- MetaCPAN: https://metacpan.org/pod/Mojolicious
- ドキュメント集: https://docs.mojolicious.org/

## Prototype / Testing Notes

- 実験的なコードや最小サンプルは `agents/research/examples/` に置く可能性がある（ユーザ許可が必要）。

## Decision / Recommendation

- 結論はこのセクションにまとめる。

## Status History

- 2025-12-16: スパイク文書を作成。Parse spike todo を実行中。

## Core concepts & examples

### ルーティング（Routing）

基本は `routes` でルートを定義し、`to` でコントローラ/アクションへ紐付ける。

```
use Mojolicious::Lite -signatures;

get '/hello/:name' => sub ($c) {
	my $name = $c->stash('name');
	$c->render(text => "Hello $name");
};

app->start;
```

ルートはプレースホルダ（`:id`, `#name`, `*path`）や条件、ネスト、名前付きルート等をサポートする。

### コントローラ（Controller）

フルアプリでは `startup` でルータを組み、`MyApp::Controller::*` に処理を置く。

```
package MyApp;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
	my $r = $self->routes;
	$r->get('/')->to('example#welcome');
}

package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub welcome ($self) { $self->render(text => 'Welcome'); }
```

### テンプレート（Rendering / Embedded Perl）

`.ep` テンプレート（Embedded Perl）をサポート。`stash` で値を渡す。

```
get '/time' => sub ($c) {
	$c->stash(now => time);
	$c->render(template => 'time');
};

__DATA__
@@ time.html.ep
The time is <%= $now %>.
```

### ヘルパーとプラグイン

アプリケーション共通処理は `helper`、再利用可能な拡張は `plugin` で実装。

```
helper debug => sub ($c, $msg) { $c->app->log->debug($msg) };
plugin 'Config' => {file => 'config/app.conf'};
```

### WebSocket（リアルタイム）

```
websocket '/echo' => sub ($c) {
	$c->on(message => sub ($c, $msg) { $c->send("echo: $msg") });
};
```

### 非同期 / 並列処理

`Mojo::IOLoop`, `Mojo::Promise`, `ua->get_p` などを使い、非同期処理を組める。

```
get '/titles' => sub ($c) {
	my $a = $c->ua->get_p('https://mojolicious.org');
	my $b = $c->ua->get_p('https://metacpan.org');
	Mojo::Promise->all($a, $b)->then(sub ($a,$b) {
		$c->render(json => {a => $a->[0]->result->dom->at('title')->text});
	})->wait;
};
```

以上を踏まえ、次は「デプロイ / ベストプラクティス」の調査に移ります。

