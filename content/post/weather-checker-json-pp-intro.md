---
title: "第2回-JSON::PPでJSON解析入門 - お天気チェッカーを作ってみよう"
draft: true
tags:
  - perl
  - json-pp
  - decode-json
description: "Perl 5.14以降のコアモジュールJSON::PPを使ってJSONをPerlデータ構造に変換する方法を解説。decode_jsonの使い方とネストしたデータの取り出し方を学び、お天気チェッカー作成に備えましょう。"
---

[@nqounet](https://x.com/nqounet)です。

前回は、HTTP::Tinyを使ってWebからデータを取得する方法を学びました。取得したデータは、こんな形をしていましたね。

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

この形式は **JSON（JavaScript Object Notation）** と呼ばれるデータ形式です。Web APIのほとんどがこの形式でデータを返します。今回は、このJSONをPerlで扱えるようになりましょう。

{{< linkcard "/post/weather-checker-http-tiny-intro/" >}}

## はじめに

### 前回の振り返り

前回学んだことを簡単に振り返ります。

- HTTP::TinyでWebからデータを取得できる
- レスポンスはハッシュリファレンスで返される
- `$response->{content}` でレスポンスの本文を取得できる

### 今回のゴール

今回のゴールは、**JSONをPerlで扱えるようになる** ことです。具体的には以下を学びます。

- JSON::PPで `decode_json` を使ってJSONをPerlデータに変換する
- ネストしたデータ構造から値を取り出す

## JSON::PPでJSONを変換しよう

### JSON::PPとは

**JSON::PP** は、PerlでJSONを扱うためのモジュールです。

- Perl 5.14以降の **コアモジュール** として標準搭載
- 追加インストール不要ですぐに使える
- Pure Perl（純粋なPerlのみ）で書かれており、どの環境でも動作する

「PP」は「Pure Perl」の略です。HTTP::Tinyと同様に、コアモジュールなのでインストール不要で使えます。

### JSONとPerlデータ構造の対応

JSON::PPは、JSONをPerlのデータ構造に変換してくれます。対応関係を見てみましょう。

```text
JSON                          Perl
─────────────────────────────────────────
{ "key": "value" }      →    { key => 'value' }    （ハッシュ）
[ 1, 2, 3 ]             →    [ 1, 2, 3 ]           （配列）
"string"                →    'string'              （文字列）
123                     →    123                   （数値）
true / false            →    1 / 0                 （真偽値）
null                    →    undef                 （未定義値）
```

重要なポイントは以下の2つです。

- JSONの `{ }` はPerlの **ハッシュリファレンス** になる
- JSONの `[ ]` はPerlの **配列リファレンス** になる

Mooシリーズで学んだリファレンスの知識が活きてきますね。

### 【コード例1】decode_jsonでPerlデータに変換

さっそく、JSON::PPを使ってJSONをPerlデータに変換してみましょう。

```perl
# Perl 5.14以降
# 外部依存: なし（JSON::PPはコアモジュール）

use strict;
use warnings;
use JSON::PP;

# JSON形式の文字列
my $json_text = '{"city": "Tokyo", "temp": 15.5}';

# JSONをPerlデータ構造に変換
my $data = decode_json($json_text);

# データを取り出して表示
print "都市: ", $data->{city}, "\n";
print "気温: ", $data->{temp}, "℃\n";
```

実行結果：

```text
都市: Tokyo
気温: 15.5℃
```

**コードのポイント**

- `use JSON::PP;` で `decode_json` 関数が使えるようになる
- `decode_json($json_text)` でJSONをPerlデータに変換
- 変換結果は **ハッシュリファレンス** なので、`$data->{key}` でアクセス

たった1行の `decode_json` で、JSON文字列がPerlで扱えるデータに変わりました！

## ネストしたデータから値を取り出そう

### ネストとは

実際のWeb APIが返すJSONは、もっと複雑な構造をしています。「ネスト（入れ子）」とは、データの中にさらにデータが入っている状態のことです。

```json
{
  "name": "Tokyo",
  "main": {
    "temp": 15.5,
    "humidity": 60
  },
  "weather": [
    { "description": "晴天" }
  ]
}
```

この例では：

- `"main"` の値として **ハッシュ** がネストしている
- `"weather"` の値として **配列** がネストし、その中にさらにハッシュがある

### ネストしたデータの読み方

図で表すと、以下のような構造になっています。

```text
$data
  │
  ├── {name}      → "Tokyo"         （文字列）
  │
  ├── {main}      → { ... }         （ハッシュリファレンス）
  │     │
  │     ├── {temp}     → 15.5       （数値）
  │     └── {humidity} → 60         （数値）
  │
  └── {weather}   → [ ... ]         （配列リファレンス）
        │
        └── [0]        → { ... }    （ハッシュリファレンス）
              │
              └── {description} → "晴天"
```

### 【コード例2】天気データから必要な情報を取り出す

次回使うOpenWeatherMap APIのレスポンス形式に似たデータを解析してみましょう。

```perl
# Perl 5.14以降
# 外部依存: なし（JSON::PPはコアモジュール）

use strict;
use warnings;
use JSON::PP;

binmode STDOUT, ':utf8';

# 天気APIのレスポンス例（次回実際に取得するデータの形式）
# 実際のAPIからはUTF-8のバイト列として返ってくる
my $json_text = '{"name":"Tokyo","main":{"temp":15.5,"humidity":60},"weather":[{"description":"sunny"}]}';

# JSONをPerlデータ構造に変換
my $data = decode_json($json_text);

# ネストしたデータから値を取り出す
my $city    = $data->{name};
my $temp    = $data->{main}{temp};
my $weather = $data->{weather}[0]{description};

print "City: $city\n";
print "Weather: $weather\n";
print "Temperature: ${temp} C\n";
```

実行結果：

```text
City: Tokyo
Weather: sunny
Temperature: 15.5 C
```

**アロー演算子を連結して辿るコツ**

ネストしたデータにアクセスするには、アロー演算子 `->` を連結します。

```perl
# 1階層目（ハッシュ）
$data->{name}                    # "Tokyo"

# 2階層目（ハッシュの中のハッシュ）
$data->{main}{temp}              # 15.5
$data->{main}->{temp}            # 同じ意味（->は省略可能）

# 2階層目（ハッシュの中の配列の0番目）
$data->{weather}[0]              # { "description": "sunny" }

# 3階層目（さらにその中のハッシュ）
$data->{weather}[0]{description} # "sunny"
```

Perlでは、隣り合う `}{` や `][` の間のアロー演算子は省略できます。どちらのスタイルで書いても同じ意味になります。

**日本語を扱うための注意点**

次回のOpenWeatherMap APIでは、日本語の天気説明（「晴天」「曇り」など）を取得できます。日本語を正しく表示するには、以下の設定が必要です。

```perl
binmode STDOUT, ':utf8';     # 標準出力をUTF-8モードに設定
```

`decode_json` はUTF-8のバイト列をデコードし、PerlのUTF-8フラグ付き文字列を返します。この文字列を正しく出力するために、`binmode` で標準出力のエンコーディングを設定します。詳しくは次回の記事で実際にAPIを呼び出しながら解説します。

## まとめ

今回学んだことを振り返りましょう。

- **JSON::PP** はPerl 5.14以降のコアモジュールで、追加インストール不要
- `decode_json` でJSONをPerlデータ構造に変換できる
- JSONの `{ }` はハッシュリファレンス、`[ ]` は配列リファレンスになる
- ネストしたデータには **アロー演算子を連結** してアクセスする
- 日本語を扱う場合は `binmode STDOUT, ':utf8';` を設定する

### 次回予告

次回は、いよいよOpenWeatherMap APIに接続して **実際の天気情報** を取得します。今回学んだHTTP通信とJSON解析を組み合わせて、本物の天気データを取得してみましょう！

{{< linkcard "https://perldoc.perl.org/JSON::PP" >}}
