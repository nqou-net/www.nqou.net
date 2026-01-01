---
title: '第9回-元のURLを探そう — URL短縮サポーターを作ってみよう'
draft: true
description: '短縮コードから元のURLを検索する方法を学びます。SELECT文とfetchrow_hashrefでデータベースからデータを取得しましょう。'
tags:
  - perl
  - sql-select
  - data-retrieval
---

[@nqounet](https://x.com/nqounet)です。

連載「URL短縮サポーターを作ってみよう」の第9回です。

## 前回の振り返り

第8回では、プレースホルダルーティングを使って、動的なURLパスから短縮コードを取得する方法を学びました。

{{< linkcard "#" >}}

前回学んだ内容を簡単に振り返ります。

- プレースホルダルーティング（`/:code`形式）で動的なURLパスを処理できる
- `$c->param('code')`でプレースホルダの値を取得できる
- `$c->app->log->info(...)`でサーバーログに情報を出力できる
- プレースホルダルーティングは他のルートより後に定義すべきである

今回は、取得した短縮コードを使って、データベースから元のURLを検索する方法を学びます。

## 今回のゴール

第9回では、以下を達成することを目標とします。

- SELECT文でデータベースからデータを取得する方法を理解する
- `fetchrow_hashref`で検索結果を扱う
- 検索結果が見つからない場合の対処法を学ぶ

## 元のURLはどこにある？

### タカシさんの疑問

短縮コードを取得できるようになったタカシさん。次の疑問が湧いてきました。

「`abc123`という短縮コードでアクセスされたのはわかった。でも、この短縮コードに対応する元のURLはどうやって調べるの？」

良い質問です。第7回でデータベースに保存したURLを、今度は取り出す必要があります。ここで登場するのがSELECT文です。

### SELECT文とは

SELECT文は、データベースからデータを取得するためのSQL文です。基本的な構文は以下のとおりです。

```sql
SELECT カラム名 FROM テーブル名 WHERE 条件
```

今回の場合、`urls`テーブルから`short_code`が一致するレコードの`original_url`を取得したいので、以下のようなSQL文になります。

```sql
SELECT original_url FROM urls WHERE short_code = 'abc123'
```

しかし、ユーザー入力をそのままSQL文に埋め込むのは危険です。第7回で学んだとおり、プレースホルダを使って安全に実行しましょう。

## SELECT文をPerlで実行する

### prepareとexecute

INSERT文と同様に、SELECT文もprepareとexecuteを使って実行します。

```perl
#!/usr/bin/env perl
# select_example.pl（抜粋）
# Perl: 5.10以上
# 依存: DBI, DBD::SQLite（cpanmでインストール）
my $sth = $dbh->prepare("SELECT original_url FROM urls WHERE short_code = ?");
```

このコードでは、`?`がプレースホルダです。実際の短縮コードは`execute`で渡します。

```perl
$sth->execute($code);
```

ここまではINSERT文と同じ流れです。違いは、SELECT文では実行後に「結果を取得する」ステップが必要な点です。

### fetchrow_hashrefで結果を取得

SELECT文の実行結果を取得するには、`fetchrow_hashref`メソッドを使います。

```perl
#!/usr/bin/env perl
# select_example.pl（抜粋）
# Perl: 5.10以上
# 依存: DBI, DBD::SQLite（cpanmでインストール）
my $row = $sth->fetchrow_hashref;
```

`fetchrow_hashref`は、検索結果の1行をハッシュリファレンスとして返します。カラム名がキーになるため、以下のようにアクセスできます。

```perl
if ($row) {
    my $original_url = $row->{original_url};
    print "元のURL: $original_url\n";
}
```

ハッシュリファレンスを使うと、カラム名で直接値を取得できるため、コードが読みやすくなります。

### 見つからない場合の対処

短縮コードがデータベースに存在しない場合、`fetchrow_hashref`は`undef`を返します。この場合の対処も実装しましょう。

```perl
if ($row) {
    my $original_url = $row->{original_url};
    # 見つかった場合の処理
} else {
    # 見つからなかった場合の処理
    print "短縮コードが見つかりません。\n";
}
```

この分岐により、存在しない短縮コードへのアクセスにも適切に対応できます。

## 実際のコードを見てみよう

### 完全なスクリプト

ここまでの内容を組み合わせた完全なスクリプトを見てみましょう。

```perl
#!/usr/bin/env perl
# lookup_url.pl
# Perl: 5.10以上
# 依存: DBI, DBD::SQLite（cpanmでインストール）
use strict;
use warnings;
use DBI;

# データベースに接続
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=urls.db",
    "",
    "",
    { RaiseError => 1, AutoCommit => 1 }
);

# 検索する短縮コード（実際のアプリではルートから受け取る）
my $code = 'abc123';

# SELECT文を準備
my $sth = $dbh->prepare("SELECT original_url FROM urls WHERE short_code = ?");

# 値を渡して実行
$sth->execute($code);

# 結果を取得
my $row = $sth->fetchrow_hashref;

if ($row) {
    print "元のURL: $row->{original_url}\n";
} else {
    print "短縮コード '$code' は見つかりませんでした。\n";
}

# 切断
$dbh->disconnect;
```

コードの流れを解説します。

#### SELECT文の準備と実行

```perl
my $sth = $dbh->prepare("SELECT original_url FROM urls WHERE short_code = ?");
$sth->execute($code);
```

プレースホルダを使ってSQL文を準備し、`execute`で短縮コードを渡します。INSERT文と同じパターンです。

#### 結果の取得と判定

```perl
my $row = $sth->fetchrow_hashref;

if ($row) {
    print "元のURL: $row->{original_url}\n";
} else {
    print "短縮コード '$code' は見つかりませんでした。\n";
}
```

`fetchrow_hashref`で結果を取得し、値が存在するかどうかで分岐します。

## 動作確認

### スクリプトを実行する

上記のコードを`lookup_url.pl`として保存し、ターミナルで実行してください。

```bash
perl lookup_url.pl
```

第7回で登録した短縮コードを使用すれば、以下のような出力が表示されます。

```
元のURL: https://example.com/very-long-url-that-needs-shortening
```

存在しない短縮コードを指定した場合は、以下のように表示されます。

```
短縮コード 'xyz999' は見つかりませんでした。
```

### Mojoliciousアプリに組み込む

第8回で作成したプレースホルダルーティングに、今回のSELECT処理を組み込むと、以下のようになります。

```perl
get '/:code' => sub ($c) {
    my $code = $c->param('code');

    my $sth = $dbh->prepare("SELECT original_url FROM urls WHERE short_code = ?");
    $sth->execute($code);
    my $row = $sth->fetchrow_hashref;

    if ($row) {
        $c->app->log->info("元のURL: $row->{original_url}");
        $c->render(text => "元のURL: $row->{original_url}");
    } else {
        $c->render(status => 404, text => '短縮コードが見つかりません');
    }
};
```

存在しない短縮コードへのアクセスには、HTTPステータスコード404（Not Found）を返すのが適切です。

## まとめ

### 今回学んだこと

第9回では、以下のことを学びました。

- SELECT文とプレースホルダでデータベースからデータを安全に検索できる
- `$sth->fetchrow_hashref`で検索結果をハッシュリファレンスとして取得できる
- 結果が見つからない場合は`undef`が返されるため、`if ($row)`で分岐する
- 見つからない場合は404エラーを返すのが適切である

### 次回予告

次回は「転送しよう！ — リダイレクトの魔法」をテーマに、取得した元のURLへ自動的にリダイレクトする方法を学びます。いよいよURL短縮サービスの核心機能が完成します。お楽しみに。
