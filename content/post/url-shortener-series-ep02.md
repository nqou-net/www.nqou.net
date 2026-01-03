---
title: '第2回-まずは入口を作ろう — URL短縮サポーターを作ってみよう'
draft: true
description: 'URL短縮サービスの入口となるフォームを作成します。Mojolicious::LiteのGETルーティングとEPテンプレートで、URLを入力できる画面を表示しましょう。'
tags:
  - perl
  - html-form
  - web-input
---

[@nqounet](https://x.com/nqounet)です。

連載「URL短縮サポーターを作ってみよう」の第2回です。

## 前回の振り返り

第1回では、友人のタカシさんから「長いURLを短くしたい」という相談を受け、Mojolicious::Liteを使ってURL短縮サービスを作り始めました。

前回学んだ内容を簡単に振り返ります。

- cpanmでMojoliciousをインストールした
- `use Mojolicious::Lite -signatures;`でWebアプリケーションの雛形を作成した
- morboで開発サーバーを起動し、ブラウザにHello Worldを表示した

今回は、タカシさんがURLを入力できる画面を作っていきます。

## 今回のゴール

第2回では、以下を達成することを目標とします。

- GETルーティングとEPテンプレートの仕組みを理解する
- `__DATA__`セクションにHTMLテンプレートを埋め込む
- URLを入力できるフォームを表示する

## どこからURLを入力する？

### フォームが必要

前回のHello Worldは、ただ文字を表示するだけのページでした。しかし、URL短縮サービスを作るには、ユーザーが「短縮したいURL」を入力できる場所が必要です。

Webアプリケーションでユーザーから情報を受け取る最も基本的な方法は、HTMLフォームです。タカシさんがURLを入力し、「短縮！」ボタンを押すと、そのURLがサーバーに送信される――そんな画面を作っていきます。

### GETルーティングとテンプレート

前回のコードでは、`$c->render(text => 'Hello World!');`のように、Perlのコード内に直接テキストを書いていました。しかし、HTMLを書くとなると、コード内に長々とHTMLを書くのは読みにくくなります。

Mojolicious::Liteでは、`__DATA__`セクションにHTMLテンプレートを埋め込むことができます。このテンプレートはEP（Embedded Perl）と呼ばれ、HTMLの中にPerlのコードを埋め込める形式です。

ルート定義で`get '/' => 'index';`と書くと、Mojoliciousは`__DATA__`セクション内の`@@ index.html.ep`というテンプレートを探してレンダリングしてくれます。

## テンプレートを使ったルーティング

### コードを書き換える

前回作成した`app.pl`を以下のように書き換えてください。

```perl
#!/usr/bin/env perl
# app.pl
# Perl: 5.20以上（サブルーチンシグネチャ使用）
# 依存: Mojolicious
use Mojolicious::Lite -signatures;

get '/' => 'index';

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>URL短縮サポーター</title>
</head>
<body>
    <h1>URL短縮サポーター</h1>
    <p>短縮したいURLを入力してください。</p>
    <form method="post" action="/shorten">
        <input type="url" name="url" placeholder="https://example.com/very-long-url..." required>
        <button type="submit">短縮！</button>
    </form>
</body>
</html>
```

コードの各部分を解説します。

#### GETルーティングの定義

```perl
get '/' => 'index';
```

この1行がGETルーティングの定義です。`/`（ルートURL）へのGETリクエストを受け取ったら、`index`という名前のテンプレートをレンダリングするという意味です。

前回のように無名サブルーチンで処理を書くこともできますが、単純にテンプレートを表示するだけならこの書き方がシンプルです。

#### `__DATA__`セクション

Perlでは`__DATA__`より後ろに書いた内容は、プログラムの実行コードとしては扱われません。Mojoliciousはこの領域を活用して、テンプレートファイルを埋め込めるようにしています。

#### テンプレートの宣言

```
@@ index.html.ep
```

この行は「ここから`index.html.ep`というテンプレートが始まる」という宣言です。`index`がテンプレート名、`.html`が出力形式、`.ep`がEP（Embedded Perl）テンプレートであることを示しています。

ルート定義の`'index'`と、テンプレート名の`index`が対応していることがポイントです。

### フォームのHTML

テンプレートの中核となるのは、以下のフォーム部分です。

```html
<form method="post" action="/shorten">
    <input type="url" name="url" placeholder="https://example.com/very-long-url..." required>
    <button type="submit">短縮！</button>
</form>
```

HTMLフォームの各属性を確認しましょう。

- `method="post"`: フォーム送信時にPOSTリクエストを使用する
- `action="/shorten"`: 送信先のURLを`/shorten`に設定する
- `type="url"`: ブラウザにURL形式の入力であることを伝える
- `name="url"`: サーバー側でこの入力値を取得するときのキー名
- `required`: 入力必須であることを指定する

「短縮！」ボタンを押すと、入力されたURLが`/shorten`というパスにPOSTリクエストとして送信されます。ただし、今回は`/shorten`へのルートはまだ定義していないので、ボタンを押すとエラーになります。それは次回のテーマです。

## 動作確認

### morboで起動する

ファイルを保存したら、morboで起動しているサーバーが自動的にリロードされます。もしサーバーを停止していた場合は、再度以下のコマンドを実行してください。

```bash
morbo app.pl
```

### ブラウザで確認する

`http://localhost:3000`にアクセスすると、「URL短縮サポーター」というタイトルと入力フォームが表示されます。

テキストボックスに適当なURL（例: `https://example.com/test`）を入力して「短縮！」ボタンを押してみてください。まだ`/shorten`へのルートを定義していないため、「Page not found」というエラーページが表示されますが、それで正常です。フォームからサーバーにデータを送信する仕組みは、すでに動いています。

## まとめ

### 今回学んだこと

第2回では、以下のことを学びました。

- `get '/' => 'index';`で、テンプレートを使ったGETルーティングを定義する方法
- `__DATA__`セクションにEPテンプレートを埋め込む方法
- HTMLフォームの基本（`method`、`action`、`name`属性）

### 次回予告

次回は「入力を受け取ろう — POSTリクエストの処理」をテーマに、フォームから送信されたURLをサーバー側で受け取る方法を学びます。`$c->param('url')`で入力値を取得し、短縮処理への準備を整えます。お楽しみに。
