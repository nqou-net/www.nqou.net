---
date: 2025-12-30T12:00:00+09:00
description: Webルーティングの主要概念とフレームワーク（PerlのRouter::Simpleを中心に）を整理し、設計・実装時の観点をまとめた調査メモ。
draft: false
epoch: 1767063600
image: /favicon.png
iso8601: 2025-12-30T12:00:00+09:00
slug: web-routing-frameworks
tags:
  - routing
  - web-framework
  - perl
title: Webルーティングフレームワークの整理（Router::Simple含む）
---

## タイトル
Webルーティングフレームワークの整理（Router::Simple含む）

作成日: 2025-12-30

目的: Webルーティングの主要機能・設計観点と、Perlの Router::Simple を含む代表的フレームワークの特徴を整理する。

---

## 要約

- ルーティングは「パス・HTTPメソッド・ホスト等の条件 → ハンドラ/コントローラ」を解決する責務。検索クエリの精度と順序、メンテナンス性が品質を左右する
- Router::Simple はシンプルなパスマッチと条件付きマッチ、逆引き（URI生成）を提供し、Plack/PSGI と組み合わせて柔軟に組み立てられる軽量ルーター
- Perl主要フレームワーク（Mojolicious, Dancer2, Catalyst）はそれぞれにルーターを同梱し、ミドルウェア・パラメータ検証・ネームドルート・プラグイン連携の厚さが異なる
- 設計では「命名規約 vs 明示ルート」「ミドルウェアの粒度」「逆引き/URLヘルパ」「テストのしやすさ」を軸に選定する

---

## 1. ルーティングの主要概念

- パスマッチ: 静的セグメント `/about` と動的セグメント `/:id`、ワイルドカード `/*rest`
- 条件付け: HTTPメソッド、Host/Schema/Port、Accept/Content-Type、パラメータの正規表現制約
- 優先順位: 具体的パスを先に、ワイルドカードを後ろに定義するのが定石
- 逆引き（URL生成）: ルート名＋パラメータからURLを組み立て、ハードコードを避ける
- ミドルウェア接続: 認証・ロギングなどをルート単位、グループ単位で差し込む
- ローカル/マウント: サブルーターをパスプレフィックス付きでマウントし、ドメインやコンテキスト毎に分割する

---

## 2. Router::Simple（Perl）の特徴と使い方

### 2.1 概要
- CPAN: Router::Simple（純粋Perl、依存が少ない軽量ルーター）
- 主要機能: パスパラメータ、正規表現制約、HTTPメソッド/Host/Schema 条件、`uri_for` による逆引き、Plack/PSGIとの連携
- 非ゴール指向: ルーティングのみ提供し、ミドルウェアやレスポンス生成は別コンポーネントで組み立てる設計

### 2.2 最小コード例
```perl
use Router::Simple;
my $router = Router::Simple->new;

$router->connect('/articles/{id}', {controller => 'Article', action => 'show'},
  {id => qr/\d+/, method => ['GET']});

if (my $p = $router->match({ PATH_INFO => '/articles/42', REQUEST_METHOD => 'GET' })) {
    # $p => { controller => 'Article', action => 'show', id => '42' }
}

my $url = $router->uri_for({ controller => 'Article', action => 'show', id => 99 });
# => "/articles/99"
```

### 2.3 条件・制約の指定例
- パラメータ検証: `id => qr/\d+`、`slug => qr{[a-z0-9-]+}`
- メソッド: `method => ['GET','HEAD']`
- ホスト/スキーム: `{ host => 'admin.example.com', scheme => 'https' }`
- on_matchフック: マッチ後にマッピングを書き換えるコールバックを登録可能
- 優先順位: 具体ルートを先に `connect` し、ワイルドカードやフォールバックは後ろに置く

### 2.4 Plack/PSGI との統合の例
```perl
use Plack::Builder;
use Router::Simple;

my $router = Router::Simple->new;
$router->connect('/', {app => sub { [200,['Content-Type'=>'text/plain'],['home']] }});
$router->connect('/health', {app => sub { [200,['Content-Type'=>'text/plain'],['ok']] }}, {method => ['GET']});

my $app = sub {
    my $env = shift;
    if (my $p = $router->match($env)) {
        return $p->{app}->($env);
    }
    return [404, ['Content-Type'=>'text/plain'], ['not found']];
};

builder {
    enable 'AccessLog';
    $app;
};
```

### 2.5 運用ヒント
- テスト: `Router::Simple::SubMapper` を使うと同じプレフィックスのルート定義をまとめやすい
- 逆引き: テンプレート側で `uri_for` を介し、URL文字列の直書きを避ける
- パフォーマンス: ルート定義が多い場合はワイルドカードを減らし、具体度の高い順で宣言する
- 役割分担: ルーターはプレーンなままにし、バリデーションや認可は Plack ミドルウェアやアクション層で実施する

---

## 3. Perlの他ルーティング実装との比較

| フレームワーク | ルーティングの特徴 | 逆引き | ミドルウェア | 備考 |
| --- | --- | --- | --- | --- |
| Router::Simple | 軽量、パス/メソッド/ホスト条件、Plackと組みやすい | `uri_for` | Plackで自由に構成 | シンプルさ重視、PSGI前提 |
| Mojolicious | `routes` DSL、ウェブソケット/ネスト/橋渡しフック、`under` でガード | `url_for` | before/around hooks + Plugins | フルスタック、ノンブロッキングI/O |
| Dancer2 | `get '/path' => sub {}` DSL、チェイン可能なフック、`prefix` でサブルーター | `uri_for` | PSGIミドルウェア + Dancer hooks | 軽量フルスタック、設定ファイル駆動 |
| Catalyst | `Chained` アクション、キャプチャードルートで階層設計 | `uri_for` | `auto`/`end` アクション + Plack | 大規模向け、規約とコンポーネントが充実 |
| Plack::App::URLMap | パスプレフィックスでアプリをマウント | なし | PSGIミドルウェア | 単純マウント、細粒ルーティングは別途 |

---

## 4. 他言語の代表的ルーター（比較用）

- Node.js: Express/Fastify — 中間ウェアチェーン、パス/メソッドルート、スキーマバリデーション(Fastify+JSON Schema)、プラグイン豊富
- Python: Flask/Starlette/FastAPI — デコレータDSL、型ヒント/バリデーション（Pydantic）、ASGIミドルウェア
- Ruby: Rails Router/Sinatra — ネームドルートとRESTful資源ルート、パイプラインミドルウェア(Rack)
- Java/Kotlin: Spring Boot — `@RequestMapping` / `@GetMapping`、フィルタ/Interceptor、PathVariableとValidator

比較観点: DSLの明快さ、逆引きサポート、バリデーションの標準装備、ミドルウェアの粒度、非同期I/O対応、プラグインエコシステムの厚さ。

---

## 5. 選定と設計の観点

- シンプル志向: ルーティングだけを自由に組みたい → Router::Simple + Plack ミドルウェア
- フルスタック志向: ルーティングとテンプレ・セッション・WS等を統合 → Mojolicious / Dancer2 / Catalyst
- URLの逆引き必須: テンプレートやAPIクライアントでURL生成を多用するなら、ネームドルートとヘルパが揃った実装を選ぶ
- 認可/認証: ルート単位のガードが必要なら、`under`（Mojolicious）やフィルタ（Spring/Express）などフックの粒度を確認する
- テスト容易性: ルート定義をモジュール分割し、テーブル駆動でマッチングテストを書く（Router::Simpleはハッシュで検証しやすい）

---

## 6. 参考リンク（公式・ドキュメント）

- Router::Simple (CPAN): https://metacpan.org/pod/Router::Simple
- Router::Simple::SubMapper: https://metacpan.org/pod/Router::Simple::SubMapper
- Mojolicious Guides: https://docs.mojolicious.org/Mojolicious/Guides/Routing
- Dancer2 Routing: https://metacpan.org/pod/distribution/Dancer2/lib/Dancer2/Manual/Routes.pod
- Catalyst Chained Actions: https://metacpan.org/pod/Catalyst/DispatchType/Chained
- Plack::App::URLMap: https://metacpan.org/pod/Plack::App::URLMap
