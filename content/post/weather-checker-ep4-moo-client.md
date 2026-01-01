---
title: "第4回-お天気チェッカーを完成させよう - お天気チェッカーを作ってみよう"
draft: true
tags:
  - perl
  - moo
  - api-client
description: "Mooで学んだオブジェクト指向を活かしてWeatherClientクラスを実装。has/sub、required/default、カプセル化、型制約を総動員してお天気チェッカーを完成させます。"
---

[@nqounet](https://x.com/nqounet)です。

「お天気チェッカーを作ってみよう」シリーズも、いよいよ最終回です。これまでに学んだ知識を総動員して、再利用可能な **WeatherClientクラス** を作成し、お天気チェッカーを完成させましょう。

{{< linkcard "/post/weather-checker-openweathermap/" >}}

## 前回の振り返り

これまでのシリーズで学んだことを振り返ります。

| 回 | テーマ | 学んだこと |
|:--|:--|:--|
| 第1回 | HTTP通信入門 | HTTP::TinyでWebからデータを取得 |
| 第2回 | JSON解析 | JSON::PPでJSONをPerlデータに変換 |
| 第3回 | API連携 | OpenWeatherMap APIで天気情報を取得 |

前回のコードは動作しましたが、スクリプトの中にすべての処理が書かれていました。今回は、これを **クラス** にまとめて、再利用しやすい形に整えます。

## なぜクラスにするのか

### 前回のコードの問題点

前回のコードを振り返ってみましょう。

```perl
my $api_key = $ENV{OPENWEATHERMAP_API_KEY}
    or die "...";
my $url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$api_key&...";
my $http = HTTP::Tiny->new(timeout => 10);
my $response = $http->get($url);
# ... 以下、データ処理
```

このコードには以下の問題があります。

- **再利用が難しい**: 別の都市の天気を取得するには、コードをコピー＆ペーストする必要がある
- **設定が散らばっている**: APIキー、タイムアウト、URLなどが別々の場所にある
- **テストしにくい**: HTTPクライアントを差し替えてテストすることができない

### クラスにまとめるメリット

**WeatherClient** クラスを作成することで、これらの問題を解決できます。

```perl
# クラスを使った場合（これが今回のゴール）
my $client = WeatherClient->new(api_key => $api_key);
my $weather = $client->get_weather('Tokyo');
print "天気: $weather->{description}\n";
```

クラスにまとめるメリットは以下のとおりです。

- **再利用性**: 一度作れば、何度でも使い回せる
- **カプセル化**: 内部実装を隠蔽し、シンプルなインターフェースを提供
- **保守性**: 変更が必要な場合も、一箇所を修正するだけでよい

## WeatherClientクラスを設計しよう

### 属性の設計

Mooシリーズで学んだ知識を思い出しながら、WeatherClientクラスの属性を設計しましょう。

| 属性 | 型 | 必須/任意 | 説明 |
|:--|:--|:--|:--|
| `api_key` | Str | 必須 | OpenWeatherMapのAPIキー |
| `timeout` | Int | 任意（デフォルト10秒） | HTTPリクエストのタイムアウト |
| `_http` | - | 内部属性（lazy） | HTTP::Tinyのインスタンス |

**設計のポイント**

- `api_key` は必須（`required => 1`）。APIキーがなければ動作しない
- `timeout` は任意で、デフォルト値を設定（`default => 10`）
- `_http` は `_` で始まる内部属性。外部からは見えない（カプセル化）
- `_http` は `lazy` 属性。使われるまで作成されない（遅延初期化）

### メソッドの設計

WeatherClientクラスには、1つのメソッドを用意します。

| メソッド | 引数 | 戻り値 |
|:--|:--|:--|
| `get_weather` | 都市名（文字列） | 天気情報（ハッシュリファレンス） |

シンプルに保つことが重要です。複雑な機能は後から追加できます。

## 【コード例1】WeatherClientクラスの実装

いよいよ、WeatherClientクラスを実装しましょう。

```perl
# Perl 5.14以降
# 外部依存: Moo, Types::Standard（cpanm Moo Types::Standard でインストール）

package WeatherClient {
    use Moo;
    use HTTP::Tiny;
    use JSON::PP;
    use Types::Standard qw(Str Int);

    # 必須属性: APIキー
    has api_key => (
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    # 任意属性: タイムアウト（デフォルト10秒）
    has timeout => (
        is      => 'ro',
        isa     => Int,
        default => 10,
    );

    # 内部属性: HTTPクライアント（lazy属性）
    has _http => (
        is      => 'lazy',
        builder => '_build__http',
    );

    sub _build__http {
        my $self = shift;
        return HTTP::Tiny->new(timeout => $self->timeout);
    }

    # 天気情報を取得するメソッド
    sub get_weather {
        my ($self, $city) = @_;

        # リクエストURLを構築
        my $url = "https://api.openweathermap.org/data/2.5/weather"
                . "?q=$city"
                . "&appid=" . $self->api_key
                . "&units=metric"
                . "&lang=ja";

        # HTTPリクエストを送信
        my $response = $self->_http->get($url);

        # エラーチェック
        if (!$response->{success}) {
            die "HTTPエラー: $response->{status} $response->{reason}\n";
        }

        # JSONをPerlデータ構造に変換
        my $data = decode_json($response->{content});

        # 必要なデータを整形して返す
        return {
            city        => $data->{name},
            description => $data->{weather}[0]{description},
            temp        => $data->{main}{temp},
            humidity    => $data->{main}{humidity},
        };
    }
};

1;
```

**Mooシリーズで学んだ概念の復習**

このコードでは、Mooシリーズで学んだ多くの概念を使っています。

| 概念 | Mooシリーズの回 | 使用箇所 |
|:--|:--|:--|
| `has` と `sub` | 第2回 | 属性とメソッドの定義 |
| `required` | 第5回 | `api_key` は必須 |
| `default` | 第5回 | `timeout` のデフォルト値 |
| カプセル化 | 第6回 | `_http` は内部属性 |
| `isa`（型制約） | 第12回 | `Str`, `Int` で型を制約 |

**lazy属性とは**

`is => 'lazy'` は、属性の値が **最初に使われるまで生成されない** ことを意味します。これにより、不要なオブジェクトの生成を避けられます。

```perl
has _http => (
    is      => 'lazy',
    builder => '_build__http',  # 値を生成するメソッド
);

sub _build__http {
    my $self = shift;
    return HTTP::Tiny->new(timeout => $self->timeout);
}
```

`$self->_http` が最初に呼ばれたときに、`_build__http` メソッドが実行され、HTTP::Tinyのインスタンスが作成されます。

## 【コード例2】WeatherClientを使ってみよう

作成したWeatherClientクラスを使って、複数の都市の天気を取得してみましょう。

```perl
# Perl 5.14以降
# 外部依存: Moo, Types::Standard
# WeatherClientクラスが同じファイルまたはモジュールとして定義されている前提

use strict;
use warnings;

binmode STDOUT, ':utf8';

# WeatherClientクラスの定義（上記のコードをここに貼り付けるか、モジュール化する）
# package WeatherClient { ... }; の部分

# 環境変数からAPIキーを取得
my $api_key = $ENV{OPENWEATHERMAP_API_KEY}
    or die "環境変数 OPENWEATHERMAP_API_KEY を設定してください\n";

# WeatherClientオブジェクトを作成
my $client = WeatherClient->new(api_key => $api_key);

# 複数の都市の天気を取得
my @cities = ('Tokyo', 'Osaka', 'Kyoto');

print "=" x 40, "\n";
print "  お天気チェッカー（複数都市対応版）\n";
print "=" x 40, "\n";

for my $city (@cities) {
    my $weather = $client->get_weather($city);

    print "\n【$weather->{city}】\n";
    print "  天気: $weather->{description}\n";
    print "  気温: $weather->{temp}℃\n";
    print "  湿度: $weather->{humidity}%\n";
}

print "\n", "=" x 40, "\n";
```

実行結果の例：

```text
========================================
  お天気チェッカー（複数都市対応版）
========================================

【Tokyo】
  天気: 晴天
  気温: 15.5℃
  湿度: 60%

【Osaka】
  天気: 曇りがち
  気温: 14.2℃
  湿度: 65%

【Kyoto】
  天気: 晴天
  気温: 13.8℃
  湿度: 55%

========================================
```

**クラスを使うメリットを実感**

前回のコードと比べてみてください。

```perl
# 前回（クラスなし）
# 都市ごとにURLを構築し、HTTPリクエストを送り、JSONを解析...を繰り返す

# 今回（クラスあり）
my $weather = $client->get_weather('Tokyo');
```

たった1行で天気情報を取得できるようになりました。これがオブジェクト指向の力です。

## まとめ

シリーズ全4回を通して学んだことを振り返りましょう。

| 回 | 学んだこと |
|:--|:--|
| 第1回 | HTTP::TinyでHTTP通信の基本を学んだ |
| 第2回 | JSON::PPでJSON解析の方法を学んだ |
| 第3回 | OpenWeatherMap APIで実際の天気情報を取得した |
| 第4回 | Mooを使ってWeatherClientクラスを実装した |

今回の第4回で学んだことは以下のとおりです。

- クラスにまとめることで **再利用性** と **保守性** が向上する
- `required` と `default` で必須属性と任意属性を区別
- `lazy` 属性で遅延初期化を実現
- `_` で始まる属性でカプセル化
- `isa` で型制約を設定

### 発展的な内容

さらにスキルアップしたい方へ、発展的なトピックを紹介します。

**エラーハンドリングの強化**

本シリーズでは `die` でエラーを処理しましたが、より堅牢なプログラムには **Try::Tiny** を使った例外処理が有効です。

{{< linkcard "/2025/12/14/000000/" >}}

**より高機能なHTTPクライアント**

Cookie管理や認証が必要な場合は、**LWP::UserAgent** を検討してください。HTTP::Tinyよりも高機能なHTTPクライアントです。

{{< linkcard "https://metacpan.org/pod/LWP::UserAgent" >}}

**他のAPIへの応用**

今回学んだ知識は、他のWeb APIにも応用できます。GitHub API、Google APIs、各種公共データAPIなど、多くのサービスが同じようにHTTP+JSONで利用できます。

---

お天気チェッカーシリーズ、お疲れさまでした。Mooシリーズで学んだオブジェクト指向の知識と、今回のAPI連携の知識を組み合わせれば、さまざまなWebサービスと連携するプログラムを作れるようになります。ぜひ、自分だけのアプリケーションを作ってみてください！

{{< linkcard "https://metacpan.org/pod/Moo" >}}
