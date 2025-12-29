---
title: "第4回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - object-oriented
  - programming
description: "Messageクラスにメソッドを追加して、チャットを完成させます"
---

[@nqounet](https://twitter.com/nqounet)です。

前回は、チャットアプリの `BBS::Message` クラスを設計しました。メッセージの「内容」「投稿者」「時刻」を持つクラスができましたね。

今回は、このクラスにメソッドを追加して、実際にチャットらしく動かしてみましょう。

## メソッドを追加しよう

前回作った `BBS::Message` クラスには、データを保持するプロパティだけがありました。でも、データを持っているだけでは使いにくいですよね。

メッセージを見やすい形式で表示する機能があると便利です。そこで、表示用のメソッドを追加してみましょう。

### 表示用のメソッド

メソッドは `sub` で定義します。第2回で少し触れましたが、今回は実際に作ってみましょう。

```perl
package BBS::Message {
    use Moo;

    has content   => (is => 'ro', required => 1);
    has author    => (is => 'ro', required => 1);
    has timestamp => (is => 'ro', default => sub { time });

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            scalar(localtime($self->timestamp)),
            $self->author,
            $self->content;
    }
};
```

`format` というメソッドを追加しました。このメソッドは、メッセージを「[時刻] 投稿者: 内容」という形式の文字列にして返します。

## $selfでプロパティにアクセス

メソッドの中で、ちょっと見慣れないコードが出てきました。

```perl
my $self = shift;
```

この `$self` は、「自分自身のオブジェクト」を表す変数です。Perlでは、メソッドが呼ばれるとき、最初の引数として自動的にオブジェクト自身が渡されます。それを `shift` で受け取っています。

`$self` を使うと、そのオブジェクトのプロパティにアクセスできます。

- `$self->content` — 自分の `content` プロパティの値を取得
- `$self->author` — 自分の `author` プロパティの値を取得
- `$self->timestamp` — 自分の `timestamp` プロパティの値を取得

これがオブジェクト指向の便利なところです。メソッドの中から、自分自身のデータに自由にアクセスできるのです。

## 動かしてみよう

それでは、実際にメッセージを作って、`format` メソッドを呼び出してみましょう。

```perl
use BBS::Message;

my $msg = BBS::Message->new(
    content => 'こんにちは！',
    author  => 'nqounet',
);

print $msg->format;
# [Sun Dec 29 23:04:41 2025] nqounet: こんにちは！
```

`$msg->format` を呼び出すと、見やすい形式でメッセージが表示されます。

### 複数のメッセージを作る

チャットなので、メッセージは1つだけではありませんよね。複数のメッセージを作って表示してみましょう。

```perl
use BBS::Message;

my @messages = (
    BBS::Message->new(content => 'こんにちは！',   author => 'nqounet'),
    BBS::Message->new(content => 'はじめまして',   author => 'perl_lover'),
    BBS::Message->new(content => 'よろしく！',     author => 'moo_fan'),
);

for my $msg (@messages) {
    print $msg->format, "\n";
}
```

配列 `@messages` に複数のメッセージオブジェクトを入れて、`for` ループで1つずつ `format` を呼び出しています。

それぞれのオブジェクトは独立しているので、`$msg->format` を呼ぶと、そのオブジェクト自身のデータが使われます。これがオブジェクト指向の強みです。

## ここまでの振り返り

第1回から第4回までで、以下のことを学びました。

- 第1回：Mooで簡単なクラスを作って動かした
- 第2回：`package`、`has`、`sub` の役割を学んだ
- 第3回：`BBS::Message` クラスを設計し、プロパティを定義した
- 第4回（今回）：メソッドを追加し、`$self` でプロパティにアクセスした

これで、データを持ち、機能を提供するクラスが作れるようになりました。

## まとめ

今回は、`BBS::Message` クラスにメソッドを追加して、チャットらしく動かしてみました。

- `sub` でメソッドを定義
- `my $self = shift;` でオブジェクト自身を受け取る
- `$self->プロパティ名` でプロパティにアクセス
- 複数のオブジェクトを作って、それぞれ独立して動作させられる

次回は、メッセージを管理する仕組みを作っていきます。
