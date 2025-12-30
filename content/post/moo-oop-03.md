---
title: "第3回-同じものを何度も作れるように - Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - moo
  - constructor
description: "コピペで増えていく変数群にうんざりしていませんか？Mooのnew（コンストラクタ）を使えば、同じ構造のオブジェクトを何個でも簡単に作れます。配列とループで一括処理する方法も解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「Mooで覚えるオブジェクト指向プログラミング」シリーズの第3回です。

## 前回の振り返り

前回は、`has`と`sub`を使って、データとロジックをまとめる方法を学びました。

{{< linkcard "/moo-oop-02/" >}}

`Message`クラスを作り、`content`属性と`show`メソッドを定義しましたね。

```perl
package Message {
    use Moo;
    has content => (is => 'rw');

    sub show {
        my $self = shift;
        print "投稿: " . $self->content . "\n";
    }
};
```

今回は、このクラスを使って**複数のオブジェクトを作成する方法**を学びます。

## コピペの問題点

掲示板で3つの投稿を管理したいとしましょう。オブジェクト指向を知らなかった頃は、こんな風に書いていたかもしれません。

```perl
my $content1 = 'おはよう';
my $content2 = 'こんにちは';
my $content3 = 'こんばんは';

print "投稿: $content1\n";
print "投稿: $content2\n";
print "投稿: $content3\n";
```

変数が増えるたびに、変数名の末尾の数字を変えていく……。これでは変数が10個、100個になったときに破綻してしまいます。

変数名を考えるのも大変ですし、処理を追加するたびにコピペが必要です。まさにスパゲティコードへの入り口ですね。

## 解決策：`new`でオブジェクトを生成する

Mooのクラスには、`new`というメソッドが自動的に用意されています。これを**コンストラクタ**と呼びます。

コンストラクタは「オブジェクトを作る工場」のようなものです。同じ設計図（クラス）から、同じ構造を持つオブジェクトを何個でも作り出せます。

```perl
package Message {
    use Moo;
    has content => (is => 'rw');

    sub show {
        my $self = shift;
        print "投稿: " . $self->content . "\n";
    }
};

# newで3つのオブジェクトを作成
my $msg1 = Message->new(content => 'おはよう');
my $msg2 = Message->new(content => 'こんにちは');
my $msg3 = Message->new(content => 'こんばんは');

$msg1->show;  # 投稿: おはよう
$msg2->show;  # 投稿: こんにちは
$msg3->show;  # 投稿: こんばんは
```

`Message->new(content => '...')`と書くだけで、`content`属性を持ったオブジェクトが作られます。

変数名は相変わらず`$msg1`、`$msg2`と増えていますが、クラスの構造を変更すれば、すべてのオブジェクトに一斉に反映されます。これがオブジェクト指向の強みです。

## 応用：配列に格納してループ処理

さらに一歩進んで、オブジェクトを配列に入れてみましょう。

```perl
package Message {
    use Moo;
    has content => (is => 'rw');

    sub show {
        my $self = shift;
        print "投稿: " . $self->content . "\n";
    }
};

# オブジェクトを配列に格納
my @messages = (
    Message->new(content => 'おはよう'),
    Message->new(content => 'こんにちは'),
    Message->new(content => 'こんばんは'),
);

# ループで一括処理
for my $msg (@messages) {
    $msg->show;
}
```

これで、オブジェクトがいくつあっても、ループで簡単に処理できます。投稿が100個に増えても、`for`ループの部分は1行のままです。

配列を使えば、変数名に番号をつける必要もありません。データの追加も配列に`push`するだけです。

## まとめ

- `new`はオブジェクトを生成するメソッドで、コンストラクタと呼ばれる
- 同じクラスから複数のオブジェクトを作成できる
- オブジェクトを配列に格納すれば、ループで一括処理できる
- コピペで変数を増やすより、オブジェクトを増やすほうが管理しやすい

## 次回予告

次回は、属性を「勝手に書き換えられない」ようにする方法を学びます。`is => 'ro'`と`is => 'rw'`の違いを理解しましょう。お楽しみに。
