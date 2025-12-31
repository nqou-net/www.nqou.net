---
title: "第1回-HTTP::TinyでHTTP通信入門 - お天気チェッカーを作ってみよう"
draft: true
tags:
  - perl
  - http-tiny
  - http-request
description: "Perl 5.14以降のコアモジュールHTTP::Tinyを使って、Webからデータを取得する方法を解説。リクエストとレスポンスの仕組みを理解し、お天気チェッカー作成の第一歩を踏み出しましょう。"
---

[@nqounet](https://x.com/nqounet)です。

「Mooで覚えるオブジェクト指向プログラミング」シリーズでは、オブジェクト指向の基礎を学びました。今回からは、その知識を活かして **実際のWeb APIと連携するプログラム** を作っていきましょう。

新シリーズ「お天気チェッカーを作ってみよう」の第1回では、まずHTTP通信の基本を学びます。

## はじめに

### お天気チェッカーシリーズの全体像

このシリーズでは、全4回にわたって「お天気チェッカー」を作成します。

| 回 | テーマ | 学ぶこと |
|:--|:--|:--|
| 第1回 | HTTP通信入門 | HTTP::TinyでWebからデータを取得 |
| 第2回 | JSON解析 | JSON::PPでAPIレスポンスを読み解く |
| 第3回 | API連携 | OpenWeatherMap APIで天気情報を取得 |
| 第4回 | クラス設計 | MooでWeatherClientクラスを実装 |

今回は、その第一歩として「HTTP通信とは何か」を理解し、実際にPerlでWebからデータを取得してみます。

## HTTP通信とは

### ブラウザで起きていること

普段、ブラウザでWebサイトを見るとき、裏側では何が起きているのでしょうか。

```text
┌─────────────┐     リクエスト      ┌─────────────────┐
│  ブラウザ    │ ─────────────────→ │   Webサーバー    │
│             │                    │                 │
│             │ ←───────────────── │                 │
└─────────────┘     レスポンス      └─────────────────┘
```

1. ブラウザがURLを入力される
2. ブラウザがWebサーバーに **リクエスト（要求）** を送る
3. Webサーバーが **レスポンス（応答）** を返す
4. ブラウザがレスポンスを解釈してページを表示する

この「リクエストとレスポンス」のやり取りが **HTTP通信** です。HTTP（HyperText Transfer Protocol）は、Webの世界でデータをやり取りするためのルール（プロトコル）なのです。

### プログラムからWebにアクセスする

ブラウザの代わりに、Perlスクリプトがリクエストを送ることもできます。

```text
┌─────────────┐     リクエスト      ┌─────────────────┐
│   Perl      │ ─────────────────→ │   Webサーバー    │
│ スクリプト   │                    │                 │
│             │ ←───────────────── │                 │
└─────────────┘     レスポンス      └─────────────────┘
```

これができると、Webサイトからデータを自動的に取得したり、Web APIを呼び出して天気情報などを取得したりできるようになります。

## HTTP::Tinyを使ってみよう

### HTTP::Tinyとは

**HTTP::Tiny** は、PerlでHTTP通信を行うためのモジュールです。

- Perl 5.14以降の **コアモジュール** として標準搭載
- 追加インストール不要ですぐに使える
- シンプルなAPIで学習コストが低い
- 軽量で高速

今回は、テスト用のWebサービス **httpbin.org** を使って実験します。httpbin.orgは、HTTP通信のテスト用に作られた無料のサービスで、リクエストの内容をそのままレスポンスとして返してくれます。

{{< linkcard "https://httpbin.org/" >}}

### 【コード例1】最初のHTTPリクエスト

さっそく、HTTP::Tinyを使ってWebからデータを取得してみましょう。

```perl
# Perl 5.14以降
# 外部依存: なし（HTTP::Tinyはコアモジュール）

use strict;
use warnings;
use HTTP::Tiny;

# HTTP::Tinyオブジェクトを作成
my $http = HTTP::Tiny->new;

# GETリクエストを送信
my $response = $http->get('https://httpbin.org/get');

# レスポンスの内容を表示
print $response->{content};
```

このコードを`http_test.pl`として保存し、実行してみてください。

```shell
perl http_test.pl
```

以下のようなJSON形式のレスポンスが表示されます。

```json
{
  "args": {},
  "headers": {
    "Host": "httpbin.org",
    "User-Agent": "HTTP-Tiny/0.088"
  },
  "origin": "xxx.xxx.xxx.xxx",
  "url": "https://httpbin.org/get"
}
```

たった数行のコードで、Webからデータを取得できました！

**コードのポイント**

- `HTTP::Tiny->new` でHTTPクライアントオブジェクトを作成
- `$http->get($url)` でGETリクエストを送信
- レスポンスは **ハッシュリファレンス** として返される
- `$response->{content}` でレスポンスの本文（ボディ）を取得

## レスポンスの中身を確認しよう

### レスポンスはハッシュリファレンス

HTTP::Tinyの`get`メソッドが返すレスポンスは、**ハッシュリファレンス** です。Mooシリーズで学んだ「ハッシュリファレンス」と同じ構造ですね。

主要な3つのフィールドを覚えておきましょう。

| フィールド | 説明 |
|:--|:--|
| `success` | 成功したかどうか（真偽値） |
| `status` | HTTPステータスコード（200、404など） |
| `content` | レスポンスの本文 |

HTTPステータスコードは、リクエストの結果を表す数字です。

- `200` - 成功（OK）
- `404` - ページが見つからない（Not Found）
- `500` - サーバー内部エラー（Internal Server Error）

### 【コード例2】レスポンスの構造を調べる

レスポンスの各フィールドを確認してみましょう。

```perl
# Perl 5.14以降
# 外部依存: なし（HTTP::Tinyはコアモジュール）

use strict;
use warnings;
use HTTP::Tiny;

my $http = HTTP::Tiny->new;
my $response = $http->get('https://httpbin.org/get');

# 成功/失敗の判定
print "成功: ", $response->{success} ? "はい" : "いいえ", "\n";

# ステータスコード
print "ステータス: ", $response->{status}, "\n";

# 内容の先頭100文字
print "内容: ", substr($response->{content}, 0, 100), "...\n";
```

実行結果：

```text
成功: はい
ステータス: 200
内容: {
  "args": {},
  "headers": {
    "Host": "httpbin.org",
    "User-Agent": "HTTP-Tiny/0.088"
  },...
```

**成功/失敗の判定が重要な理由**

HTTP通信は、ネットワークの問題やサーバーの問題で失敗することがあります。実際のプログラムでは、必ず成功/失敗を確認してから処理を進めるようにしましょう。

```perl
if ($response->{success}) {
    # 成功時の処理
    print $response->{content};
} else {
    # 失敗時の処理
    print "エラー: ", $response->{status}, " ", $response->{reason}, "\n";
}
```

`$response->{reason}` には、ステータスコードに対応するメッセージ（例：「OK」「Not Found」）が入っています。

## まとめ

今回学んだことを振り返りましょう。

- **HTTP通信** は「リクエスト（要求）」と「レスポンス（応答）」のやり取り
- **HTTP::Tiny** はPerl 5.14以降のコアモジュールで、追加インストール不要
- `get`メソッドでGETリクエストを送信できる
- レスポンスは **ハッシュリファレンス** で返される
- `success`、`status`、`content` の3つのフィールドが重要

### 次回予告

次回は、APIから返ってきたJSON形式のデータを解析する方法を学びます。「JSON::PPでJSON解析入門」をお楽しみに！

{{< linkcard "https://perldoc.perl.org/HTTP::Tiny" >}}
