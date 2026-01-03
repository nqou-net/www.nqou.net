---
date: 2025-12-31T10:00:52+09:00
description: シリーズ記事「お天気チェッカーを作ってみよう」作成のための調査・情報収集結果
draft: false
epoch: 1767222052
image: /favicon.png
iso8601: 2025-12-31T10:00:52+09:00
title: '調査ドキュメント - お天気チェッカーを作ってみよう（シリーズ記事）'
---

# 調査ドキュメント：お天気チェッカーを作ってみよう

## 調査目的

シリーズ記事「お天気チェッカーを作ってみよう」の作成に必要な技術情報の収集。

- **技術スタック**: Perl / HTTP通信 / JSON解析 / OpenWeatherMap API
- **想定読者**: Perl入学式卒業程度、「第12回-型チェックでバグを未然に防ぐ - Mooで覚えるオブジェクト指向プログラミング」（/2025/12/30/163820/）読了者
- **ゴール**: HTTP通信ができる、APIを利用できる、自然に覚えるデザインパターン
- **制約**: コード例は2つまで、新しい概念は1つまで

**調査実施日**: 2025年12月31日

---

## 1. PerlでのHTTP通信ライブラリ

### 1.1 HTTP::Tiny

**要点**:

- Perl 5.14以降のコアモジュールとして標準搭載
- 軽量・シンプル・高速をコンセプトに設計
- 外部依存がなく、ポータブル性が高い
- 基本的なHTTP/1.1クライアント機能を提供（GET、HEAD、POST、PUT、DELETE、PATCH）
- レスポンスはハッシュリファレンスで返される

**メリット**:

- 依存関係ゼロでインストール不要（Perl 5.14以降）
- 軽量で起動が速い
- シンプルなAPIで学習コストが低い
- コマンドラインワンライナーにも便利

**デメリット**:

- Cookie管理は手動（cookie_jarオプションあり）
- 認証機能が限定的
- 拡張性が低い

**使用例**:

```perl
use HTTP::Tiny;

my $http = HTTP::Tiny->new(timeout => 10);
my $response = $http->get('https://api.example.com/data');

if ($response->{success}) {
    print $response->{content};
} else {
    print "Error: $response->{status} $response->{reason}\n";
}
```

**根拠**: Perl公式ドキュメント、metacpan.org

**出典**:

- https://perldoc.perl.org/HTTP::Tiny
- https://metacpan.org/pod/HTTP::Tiny
- https://xdg.me/why-httptiny/ （設計思想の解説）

**信頼度**: 高（公式ドキュメント）

---

### 1.2 LWP::UserAgent

**要点**:

- libwww-perl（LWP）スイートの一部
- 歴史が長く、成熟したHTTPクライアント
- 豊富な機能（Cookie、認証、リダイレクト、プロキシ、HTTPS等）
- HTTP::Response オブジェクトで詳細なレスポンス情報を取得可能
- プラグインによる拡張が可能

**メリット**:

- フル機能のHTTPクライアント
- Cookie管理、認証が標準サポート
- 非HTTPプロトコル（FTP、Gopher）もサポート
- 豊富なドキュメントと実績

**デメリット**:

- 依存関係が多い（URI、HTTP::Headers等）
- 起動が遅い
- インストールが必要

**使用例**:

```perl
use LWP::UserAgent;

my $ua = LWP::UserAgent->new(timeout => 10);
my $response = $ua->get('https://api.example.com/data');

if ($response->is_success) {
    print $response->decoded_content;
} else {
    print "Error: " . $response->status_line . "\n";
}
```

**根拠**: libwww-perl公式リポジトリ、長年のPerl開発コミュニティでの実績

**出典**:

- https://github.com/libwww-perl/libwww-perl
- https://metacpan.org/pod/LWP::UserAgent
- https://lwp.interglacial.com/ch03_01.htm

**信頼度**: 高（公式ドキュメント）

---

### 1.3 使い分けの指針

| 項目 | HTTP::Tiny | LWP::UserAgent |
|------|------------|----------------|
| インストール | 不要（Perl 5.14+） | 必要 |
| 依存関係 | なし | 多い |
| 起動速度 | 高速 | 遅め |
| Cookie | 手動（cookie_jar） | 標準サポート |
| 認証 | 限定的 | フルサポート |
| HTTPS | サポート | サポート |
| レスポンス | hashref | HTTP::Response |
| 学習コスト | 低い | やや高い |

**推奨**:

- **初心者・シンプルなスクリプト**: HTTP::Tiny
- **本格的なアプリケーション・Cookie/認証が必要**: LWP::UserAgent
- **新規プロジェクト**: HTTP::Tiny から始めて、必要に応じてLWP::UserAgentへ移行

**本シリーズでの選択**: **HTTP::Tiny**

- 理由1: コアモジュールなので追加インストール不要
- 理由2: シンプルなAPIで学習に最適
- 理由3: OpenWeatherMap APIの呼び出しには十分な機能

**出典**:

- https://www.perlmonks.org/?node_id=11125103 （LWP::Simple vs HTTP::Tiny の議論）

**信頼度**: 高

---

## 2. PerlでのJSON解析

### 2.1 JSON関連モジュールの関係性

**要点**:

```
JSON::MaybeXS
    ├── Cpanel::JSON::XS (優先: 高速・安定)
    ├── JSON::XS (次点: 高速)
    └── JSON::PP (フォールバック: Pure Perl、コアモジュール)
```

- **JSON::PP**: Perl 5.14以降のコアモジュール。Pure Perlで書かれており、移植性が高いが速度は遅い
- **JSON::XS**: C言語で実装されたXSモジュール。高速だがCコンパイラが必要
- **Cpanel::JSON::XS**: JSON::XSのフォーク版。バグ修正や改善が積極的に行われている
- **JSON::MaybeXS**: 上記を自動選択するラッパー。最適なバックエンドを自動検出

### 2.2 JSON::MaybeXS

**要点**:

- 利用可能な最速のJSONモジュールを自動選択
- 優先順位: Cpanel::JSON::XS > JSON::XS > JSON::PP
- API互換性が保証される
- `encode_json` / `decode_json` をデフォルトでエクスポート

**メリット**:

- 「とりあえずこれを使えばOK」という安心感
- XSモジュールがなくてもJSON::PPにフォールバック
- 将来の移行も容易

**使用例**:

```perl
use JSON::MaybeXS;

# JSONテキストをPerlデータ構造に変換
my $data = decode_json($json_text);

# Perlデータ構造をJSONテキストに変換
my $json = encode_json($perl_data);
```

**根拠**: 多くの現代的なPerlプロジェクトで推奨されている

**出典**:

- https://metacpan.org/pod/JSON::MaybeXS
- https://perlmaven.com/comparing-the-speed-of-json-decoders

**信頼度**: 高（公式ドキュメント）

### 2.3 本シリーズでの選択

**推奨**: **JSON::PP**

- 理由1: Perl 5.14以降のコアモジュールなので追加インストール不要
- 理由2: HTTP::Tinyとの組み合わせで「コアモジュールのみ」で完結できる
- 理由3: 初心者向けには十分な速度

**代替案**: JSON::MaybeXS を紹介し、本番環境での推奨として言及

---

## 3. OpenWeatherMap API

### 3.1 概要

**要点**:

- 世界中の天気情報を提供する無料/有料のWeather API
- 現在の天気、予報、過去データなどを取得可能
- JSON/XMLで結果を返す
- 日本語での天気説明もサポート

**根拠**: OpenWeatherMap公式ドキュメント

**出典**:

- https://openweathermap.org/api
- https://openweathermap.org/current

**信頼度**: 高（公式ドキュメント）

### 3.2 Current Weather Data API

**エンドポイント**:

```
https://api.openweathermap.org/data/2.5/weather
```

**必須パラメータ**:

| パラメータ | 説明 |
|-----------|------|
| `lat` & `lon` | 緯度・経度（推奨） |
| `q` | 都市名（例: Tokyo, London,UK） |
| `appid` | APIキー（必須） |

**オプションパラメータ**:

| パラメータ | 説明 | 例 |
|-----------|------|-----|
| `units` | 単位系 | `metric`（摂氏）, `imperial`（華氏）, `standard`（ケルビン、デフォルト） |
| `lang` | 言語コード | `ja`（日本語）, `en`（英語） |
| `mode` | 出力形式 | `json`（デフォルト）, `xml`, `html` |

**APIコール例**:

```
https://api.openweathermap.org/data/2.5/weather?q=Tokyo&appid=YOUR_API_KEY&lang=ja&units=metric
```

### 3.3 レスポンスの形式

**サンプルレスポンス**:

```json
{
  "coord": { "lon": 139.6917, "lat": 35.6895 },
  "weather": [
    { "id": 800, "main": "Clear", "description": "晴天", "icon": "01d" }
  ],
  "main": {
    "temp": 15.5,
    "feels_like": 14.2,
    "temp_min": 13.0,
    "temp_max": 17.0,
    "pressure": 1020,
    "humidity": 60
  },
  "visibility": 10000,
  "wind": { "speed": 3.5, "deg": 180 },
  "clouds": { "all": 0 },
  "dt": 1609459200,
  "sys": {
    "country": "JP",
    "sunrise": 1609448400,
    "sunset": 1609483200
  },
  "timezone": 32400,
  "id": 1850147,
  "name": "Tokyo",
  "cod": 200
}
```

**主要フィールド**:

| フィールド | 説明 |
|-----------|------|
| `weather[0].description` | 天気の説明（日本語対応） |
| `main.temp` | 現在気温 |
| `main.humidity` | 湿度（%） |
| `wind.speed` | 風速（m/s） |
| `name` | 都市名 |

### 3.4 無料プランの制限

**要点**:

- 60リクエスト/分（Current Weather API）
- One Call API: 1,000リクエスト/日（無料枠）
- 商用利用可能（CC BY-SAライセンス条件あり）
- APIキー取得は無料アカウント作成のみ

**仮定**: 学習目的であれば無料プランで十分

**出典**:

- https://openweathermap.org/price

**信頼度**: 高（公式ドキュメント）

### 3.5 Perlでのサンプルコード

```perl
use HTTP::Tiny;
use JSON::PP;
use utf8;
binmode STDOUT, ':utf8';

my $api_key = 'YOUR_API_KEY';
my $city    = 'Tokyo';
my $url     = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$api_key&lang=ja&units=metric";

my $http = HTTP::Tiny->new(timeout => 10);
my $response = $http->get($url);

if ($response->{success}) {
    my $data = decode_json($response->{content});
    my $weather = $data->{weather}[0]{description};
    my $temp    = $data->{main}{temp};
    print "$city の天気: $weather\n";
    print "気温: ${temp}℃\n";
} else {
    print "エラー: $response->{status} $response->{reason}\n";
}
```

---

## 4. 関連するPerlのデザインパターン

### 4.1 HTTP通信とAPI連携でよく使うパターン

#### 4.1.1 クライアントオブジェクトパターン

**要点**:

- API接続情報（APIキー、タイムアウト等）をオブジェクトにカプセル化
- 再利用可能なHTTPクライアントを作成

```perl
package WeatherClient {
    use Moo;
    use HTTP::Tiny;
    use JSON::PP;
    use Types::Standard qw(Str Int);

    has api_key => (is => 'ro', isa => Str, required => 1);
    has timeout => (is => 'ro', isa => Int, default => 10);
    has _http   => (is => 'lazy');

    sub _build__http {
        my $self = shift;
        return HTTP::Tiny->new(timeout => $self->timeout);
    }

    sub get_weather {
        my ($self, $city) = @_;
        my $url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=" . $self->api_key . "&lang=ja&units=metric";
        my $res = $self->_http->get($url);
        return decode_json($res->{content}) if $res->{success};
        die "API Error: $res->{status}";
    }
};
```

**接続ポイント（Mooシリーズ）**:

- 第2回: `has` と `sub` でデータとロジックをまとめる
- 第5回: `required` と `default` の活用
- 第6回: カプセル化（`_http` はプライベート属性）
- 第12回: `isa` による型制約

#### 4.1.2 ファクトリパターン（軽量版）

**要点**:

- レスポンスデータから適切なオブジェクトを生成
- APIレスポンスをドメインオブジェクトに変換

```perl
package Weather {
    use Moo;
    use Types::Standard qw(Str Num);

    has city        => (is => 'ro', isa => Str);
    has description => (is => 'ro', isa => Str);
    has temperature => (is => 'ro', isa => Num);

    sub from_api_response {
        my ($class, $data) = @_;
        return $class->new(
            city        => $data->{name},
            description => $data->{weather}[0]{description},
            temperature => $data->{main}{temp},
        );
    }
};
```

### 4.2 エラーハンドリングのパターン

#### 4.2.1 Try::Tiny パターン

**要点**:

- 構造化された例外処理
- `$@` の問題を回避
- リソースのクリーンアップに `finally` が便利

```perl
use Try::Tiny;

try {
    my $response = $http->get($url);
    die "HTTP Error: $response->{status}" unless $response->{success};
    my $data = decode_json($response->{content});
    # 処理
}
catch {
    warn "エラー: $_";
}
finally {
    # クリーンアップ処理
};
```

**出典**:

- サイト内記事: 「Try::Tiny - 例外処理をスマートに」（/2025/12/14/000000/）

#### 4.2.2 リトライパターン

**要点**:

- 一時的な障害（ネットワークエラー等）に対する自動リトライ
- 指数バックオフで負荷を分散

```perl
sub fetch_with_retry {
    my ($url, $max_retries) = @_;
    $max_retries //= 3;
    
    for my $attempt (1..$max_retries) {
        my $response = $http->get($url);
        return $response if $response->{success};
        
        sleep 2 ** ($attempt - 1);  # 指数バックオフ
    }
    die "Failed after $max_retries attempts";
}
```

#### 4.2.3 Result オブジェクトパターン

**要点**:

- 成功/失敗を明示的なオブジェクトで表現
- 例外を使わないエラーハンドリング

```perl
# 成功の場合
return { success => 1, data => $weather };

# 失敗の場合
return { success => 0, error => 'API key invalid' };
```

---

## 5. 既存記事との関連性

### 5.1 Mooで覚えるオブジェクト指向プログラミングシリーズ（全12回）

**シリーズ概要**:

| 回 | タイトル | 概念 | 内部リンク |
|:--|:--|:--|:--|
| 第1回 | Mooで覚えるオブジェクト指向プログラミング | 導入、用語 | /2021/10/31/191008/ |
| 第2回 | データとロジックをまとめよう | `has`、`sub` | /2025/12/30/163810/ |
| 第3回 | オブジェクトを複数作る | `new`（コンストラクタ） | /2025/12/30/163811/ |
| 第4回 | 読み書きを制限する | `is => 'ro'`、`is => 'rw'` | /2025/12/30/163812/ |
| 第5回 | 必須と初期値を設定する | `required`、`default` | /2025/12/30/163813/ |
| 第6回 | 内部の実装を隠す | カプセル化 | /2025/12/30/163814/ |
| 第7回 | 複数のクラスを連携させる | オブジェクトの関連 | /2025/12/30/163815/ |
| 第8回 | 親クラスの機能を引き継ぐ | `extends`（継承） | /2025/12/30/163816/ |
| 第9回 | 親のメソッドを上書きする | オーバーライド | /2025/12/30/163817/ |
| 第10回 | 継承なしで機能を共有する | `Moo::Role`、`with` | /2025/12/30/163818/ |
| 第11回 | 持っているものに仕事を任せる | `handles`（委譲） | /2025/12/30/163819/ |
| 第12回 | 型チェックでバグを未然に防ぐ | `isa`（型制約） | /2025/12/30/163820/ |

### 5.2 第12回との繋がり

**第12回で学んだこと**:

- `isa`オプションで属性の型制約を指定
- `Types::Standard`モジュールの基本型（`Int`、`Str`、`Num`等）
- 型制約でバグを未然に防ぐ

**お天気チェッカーシリーズへの接続**:

1. **型制約の実践**: APIレスポンスを格納するオブジェクトで型制約を活用
2. **オブジェクト設計の応用**: WeatherClientクラス、Weatherクラスの設計
3. **カプセル化の実践**: APIキーやHTTPクライアントの隠蔽
4. **委譲の応用**: HTTPクライアントへの処理の委譲

**推奨される導入文**:

> Mooシリーズで学んだオブジェクト指向の知識を活かして、実際のWeb APIを呼び出すプログラムを作ってみましょう。

---

## 6. 内部リンク調査

### 6.1 HTTP通信関連の記事

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2025/12/22/000000.md` | PerlでのWebスクレイピング | `/2025/12/22/000000/` | **高** |
| `/content/post/2025/12/14/000000.md` | Try::Tiny - 例外処理をスマートに | `/2025/12/14/000000/` | **高** |
| `/content/post/2015/06/14/153007.md` | 第6回 #Perl鍋（HTTP::Tiny、Moo使用） | `/2015/06/14/153007/` | 中 |
| `/content/post/2025/12/16/000000.md` | Perlでの並行・並列処理（HTTP::Tiny使用例あり） | `/2025/12/16/000000/` | 中 |

### 6.2 JSON関連の記事

サイト内で直接JSON解析を解説する記事は見つからず。ただし、以下の記事でJSONが使用されている：

- `/2025/12/14/000000.md` - Try::TinyでのAPI呼び出し例
- `/2025/12/22/000000.md` - WebスクレイピングでのJSON処理

### 6.3 API関連の記事

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2025/12/01/235959.md` | Perlワンライナー入門（API呼び出し例） | `/2025/12/01/235959/` |
| `/content/post/2025/12/02/032850.md` | Perlワンライナー集（HTTP::Tiny使用例） | `/2025/12/02/032850/` |

### 6.4 Mooシリーズの記事

- 上記「5.1」のテーブルを参照

---

## 7. 競合記事の分析

### 7.1 Perl HTTP通信の日本語記事

| サイト名 | 特徴 | URL |
|---------|------|-----|
| **Perl Maven** | 英語だが詳細なチュートリアル | https://perlmaven.com/ |
| **perldoc.jp** | 公式ドキュメントの日本語訳 | https://perldoc.jp/ |

### 7.2 OpenWeatherMap APIの使い方記事

| サイト名 | 特徴 | URL |
|---------|------|-----|
| **Qiita** | OpenWeatherMapAPIの紹介 | https://qiita.com/kaito799/items/e2b6ec98c709803e648d |
| **Zenn** | OpenWeatherMap APIを使う（Go言語） | https://zenn.dev/shimpo/articles/open-weather-map-go-20250209 |
| **masakichi-code** | 天気API【OpenWeather】の使い方（PHP） | https://masakichi-code.com/blog/howto_openweather_api/ |
| **SIOS Tech Lab** | API初心者向け解説 | https://tech-lab.sios.jp/archives/36777 |

### 7.3 競合記事との差別化ポイント

**既存記事の問題点**:

1. PerlでOpenWeatherMap APIを使う日本語チュートリアルがほぼ存在しない
2. 多くの記事がJavaScript/PHP向け
3. オブジェクト指向との接続がない

**本シリーズの強み**:

1. **Mooシリーズからの連続性**: オブジェクト指向の知識を実践で活用
2. **Perl入学式の次のステップ**: 適切な難易度設定
3. **日本語での丁寧な解説**: 初心者向けのトーン
4. **コアモジュールのみで完結**: インストール不要で始められる

---

## 8. 情報源リスト（技術的正確性の担保）

### 8.1 公式ドキュメント

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **HTTP::Tiny** | https://perldoc.perl.org/HTTP::Tiny | HTTP通信の基本 |
| **LWP::UserAgent** | https://metacpan.org/pod/LWP::UserAgent | 高度なHTTP通信 |
| **JSON::PP** | https://perldoc.perl.org/JSON::PP | JSON解析（コアモジュール） |
| **JSON::MaybeXS** | https://metacpan.org/pod/JSON::MaybeXS | JSON解析（推奨） |
| **OpenWeatherMap API** | https://openweathermap.org/current | 天気API |
| **Try::Tiny** | https://metacpan.org/pod/Try::Tiny | 例外処理 |
| **Moo** | https://metacpan.org/pod/Moo | オブジェクト指向 |

### 8.2 チュートリアル・解説サイト

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **Why HTTP::Tiny?** | https://xdg.me/why-httptiny/ | HTTP::Tinyの設計思想 |
| **Perl Maven** | https://perlmaven.com/ | Perlチュートリアル |
| **PerlMonks** | https://www.perlmonks.org/ | コミュニティQ&A |

### 8.3 サイト内の関連記事

| 記事タイトル | 内部リンク | 関連内容 |
|-------------|-----------|---------|
| Try::Tiny - 例外処理をスマートに | `/2025/12/14/000000/` | エラーハンドリング |
| PerlでのWebスクレイピング | `/2025/12/22/000000/` | HTTP通信、DOM解析 |
| 第12回-型チェックでバグを未然に防ぐ | `/2025/12/30/163820/` | Mooシリーズ最終回 |
| 第1回-Mooで覚えるオブジェクト指向 | `/2021/10/31/191008/` | Mooシリーズ導入 |

---

## 9. シリーズ構成の提案

### 9.1 提案構造（全3〜4回）

#### 第1回：HTTP通信の基本

**新しい概念**: HTTP通信（リクエストとレスポンス）
**ストーリー**: Webからデータを取ってくる仕組みを理解する
**コード例**: 1) HTTP::Tinyでの基本的なGETリクエスト 2) レスポンスの確認

#### 第2回：JSONデータを扱う

**新しい概念**: JSON解析
**ストーリー**: APIからのJSONレスポンスをPerlデータ構造に変換
**コード例**: 1) JSON::PPでのdecode_json 2) データの取り出し

#### 第3回：お天気チェッカーを作ろう

**新しい概念**: APIクライアントオブジェクト
**ストーリー**: Mooで学んだ知識を活かしてWeatherClientクラスを作成
**コード例**: 1) WeatherClientクラス 2) 使用例

#### 第4回（オプション）：エラーハンドリング

**新しい概念**: 堅牢なエラー処理
**ストーリー**: 通信エラーやAPIエラーに対応する
**コード例**: 1) Try::Tinyでのエラー処理 2) リトライロジック

### 9.2 各回の制約確認

- 毎回コード例は2つまで ✓
- 新しい概念は1記事あたり1つまで ✓
- ゆっくりと少しずつ進める ✓

---

## 10. 調査結果のサマリー

### 成功要因

1. **Mooシリーズからの連続性**: オブジェクト指向の知識を実践的なAPI連携で活用
2. **コアモジュールで完結**: HTTP::Tiny + JSON::PP で追加インストール不要
3. **実用的なゴール**: 実際に動くお天気チェッカーを作成
4. **段階的な難易度**: 1記事1概念の厳密な制約

### リスクと対策

| リスク | 対策 |
|-------|------|
| APIキー取得が煩雑 | 記事内でステップバイステップで解説 |
| ネットワークエラーで挫折 | Try::Tinyでのエラーハンドリングを導入 |
| コードが複雑化 | 各回の最小限のコードのみ掲載 |
| 読者の離脱 | 各回冒頭で前回の復習、章末でまとめ |

### 技術的な推奨事項

1. **HTTP::Tiny**を使用（コアモジュール、シンプル）
2. **JSON::PP**を使用（コアモジュール）、JSON::MaybeXSは発展的なトピックとして言及
3. **OpenWeatherMap Current Weather API**を使用（シンプル、無料）
4. **Mooでのオブジェクト設計**を活用（シリーズの連続性）
5. **Try::Tiny**でのエラーハンドリングを推奨

---

**調査完了**: 2025年12月31日
**次のステップ**: シリーズ記事のアウトライン作成、第1回の執筆開始
