---
date: 2025-12-30T12:30:00+09:00
description: Webディスパッチャーの役割と設計観点、Perlを含む主要フレームワークの実装事例を整理した調査メモ。
draft: false
epoch: 1767065400
image: /favicon.png
iso8601: 2025-12-30T12:30:00+09:00
slug: dispatcher-overview
tags:
  - dispatcher
  - routing
  - perl
  - web-framework
title: Webディスパッチャーの整理（Perl事例付き）
---

## タイトル
Webディスパッチャーの整理（Perl事例付き）

作成日: 2025-12-30

目的: Webアプリケーションにおけるディスパッチャーの役割を整理し、Perlを含む複数フレームワークの具体例と設計観点をまとめる。

---

## 要約

- ディスパッチャーは「解決済みルート情報」をもとに実行対象（コントローラ/アクション/ハンドラ）を呼び出し、環境を整え、結果をレスポンスに変換する責務
- ルーターは経路決定、ディスパッチャーは実行・ライフサイクル管理という役割分担が典型（Front Controllerパターンに統合される場合も多い）
- Perlでは Router::Simple + カスタムディスパッチ、Mojolicious/Dancer2/Catalyst の組み込みディスパッチャーが代表例
- 設計の要点は「順序とフォールバック」「エラー/405処理」「ミドルウェア適用粒度」「リクエストコンテキストの受け渡し」「テスト容易性」

---

## 1. 用語と責務の整理

- ルーター: パス・メソッド等からルート情報（パラメータ、ターゲット識別子）を引く
- ディスパッチャー: ルート情報を実行対象（関数/メソッド/オブジェクト）にマッピングし、レスポンスを構築
- Front Controller: 入口ひとつでルーティングとディスパッチをまとめる構造（多くのフレームワークが採用）
- 405/404ハンドリング: マッチはしたがメソッド不一致→405、マッチなし→404を明示する実装が望ましい

---

## 2. Perlの代表的ディスパッチャー事例

### 2.1 Router::Simple + 手書きディスパッチ
- 役割分離型。Router::Simpleでルート解決し、返されたハッシュをもとにコードリファレンスやクラスメソッドを呼び出す
- サブルーターやミドルウェアは Plack::Builder で構成し、ディスパッチ部分は最小限に保つ

サンプル（PSGI環境）:
```perl
use Router::Simple;
use Plack::Request;

my $router = Router::Simple->new;
$router->connect('/articles/{id}', {controller => 'Article', action => 'show'},
  {method => ['GET'], id => qr/\d+/});

my %controller = (
  Article => {
    show => sub {
      my ($req, $captures) = @_;
      return [200, ['Content-Type' => 'text/plain'], ["article " . $captures->{id}]];
    },
  },
);

my $app = sub {
  my $env = shift;
  my $req = Plack::Request->new($env);
  my $m   = $router->match($env) or return [404, ['Content-Type'=>'text/plain'], ['not found']];
  my $code = $controller{$m->{controller}}{$m->{action}} or return [500,['Content-Type'=>'text/plain'],['handler missing']];
  return $code->($req, $m);
};
```

### 2.2 Mojolicious Dispatcher
- `Mojolicious::Routes` でルートを定義し、スタッシュにマッピングされたコントローラ/アクションを `Mojolicious::Dispatcher` が呼び出す
- `under` ルートで認可ガード、`before_dispatch`/`after_dispatch` フックで前後処理、WebSocketも同一パイプライン
- テンプレ・レンダリング、レスポンス生成まで一貫して内部で処理

### 2.3 Dancer2 Dispatcher
- DSL (`get '/foo' => sub { ... }`) を `Dancer2::Core::Dispatcher` が解決し、キーワードで得たコードリファレンスを実行
- フック（`before`, `after`, `around`）と設定ファイルを絡めて環境をセットアップ
- PSGIミドルウェアと併用しやすく、ルートプレフィックスやプラグインで拡張

### 2.4 Catalyst Dispatcher (DispatchType::Path/Chained)
- アクション属性からディスパッチ木を構築し、`Chained` により階層的・再利用的に組み立て
- `auto` や `end` で共通処理、`stash`/`context` を通じてパイプライン全体を共有
- ルート解決の柔軟性が高く、大規模アプリ向け

### 2.5 Plack::App::URLMap
- パスプレフィックスに PSGIアプリをマウントするシンプルディスパッチ。細粒なルーティングは別アプリで担当
- マイクロサービス的に小さなアプリを合成する用途で有効

---

## 3. 他言語の代表的事例（抜粋）

- Ruby on Rails: ActionDispatch が Rack環境でリクエストを受け、ルート解決後にコントローラを呼び出し、ミドルウェアスタックを経由
- Laravel (PHP): `Illuminate\Routing\Router` がルートを解決し、`ControllerDispatcher` がメソッドを呼ぶ。ミドルウェアはルート単位/グループ単位で適用
- Django (Python): URL resolver でマッチ後、ビュー関数/クラスを呼び、ミドルウェアと例外ハンドラで前後処理
- Express/Fastify (Node): ルートに積んだハンドラチェーンを順に呼ぶ。`next()` 連鎖でミドルウェアを合成

---

## 4. 設計と運用のポイント

- ルート優先順位: 具体ルートを先、ワイルドカード/キャッチオールは最後
- 405と404の分離: マッチしたがメソッド不一致の場合は405を返せる構造にする（テーブルをメソッド別に持つなど）
- ミドルウェアの粒度: 認証・ロギング・レートリミットをルート単位/グループ単位で挿入できる設計にする
- コンテキストの受け渡し: リクエストオブジェクトとルートキャプチャを束ねてハンドラに渡す（Perlなら `$req`, `$captures`）
- 例外とエラー整形: アプリ例外をHTTPレスポンスに変換するレイヤを設ける（Plack::Middleware::HTTPExceptions 等）
- 逆引き（URL生成）: ルート名＋パラメータからURLを生成するヘルパを用意し、テンプレートで直書きを避ける
- テスト容易性: ルート/ディスパッチをテーブル駆動で検証し、405/404/500の分岐を含める

---

## 5. テストの例（Router::Simple + Test::More）
```perl
use Test::More;
use Router::Simple;

my $r = Router::Simple->new;
$r->connect('/ping', {code => sub { [200, [], ['pong']] }}, {method => ['GET']});

my $m = $r->match({ PATH_INFO => '/ping', REQUEST_METHOD => 'GET' });
ok $m, 'route matched';
is $m->{code}->()->[0], 200, 'handler returns 200';

my $nm = $r->match({ PATH_INFO => '/ping', REQUEST_METHOD => 'POST' });
ok !$nm, 'POST not allowed (will be 405 at dispatcher layer)';

done_testing;
```

---

## 6. 参考リンク

- Router::Simple (CPAN): https://metacpan.org/pod/Router::Simple
- Mojolicious Dispatcher: https://docs.mojolicious.org/Mojolicious/Guides/Routing#Dispatcher
- Dancer2 Dispatcher: https://metacpan.org/pod/Dancer2::Core::Dispatcher
- Catalyst DispatchType::Chained: https://metacpan.org/pod/Catalyst/DispatchType/Chained
- Plack::App::URLMap: https://metacpan.org/pod/Plack::App::URLMap
- ActionDispatch (Rails): https://api.rubyonrails.org/classes/ActionDispatch.html
- Laravel Routing/Dispatcher: https://laravel.com/docs/routing
- Django Request/Response cycle: https://docs.djangoproject.com/en/stable/topics/http/overview/
- Express routing: https://expressjs.com/en/guide/routing.html
