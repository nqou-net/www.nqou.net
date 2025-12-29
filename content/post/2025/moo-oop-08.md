---
title: "第8回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - object-oriented
  - programming
description: "ロールを使って、複数のクラスで共通の機能を共有します"
---

[@nqounet](https://twitter.com/nqounet)です。

前回は、スレッド機能を追加しながらオブジェクトの集約について学びました。`BBS::Thread` クラスで複数のメッセージをまとめて管理できるようになりましたね。

今回は、コードの重複を解消する「ロール」という仕組みを学びましょう。

## 同じコードを何度も書いていませんか

ここまでで `BBS::Message` と `BBS::Thread` という2つのクラスを作ってきました。両方のコードを見比べてみると、似たような部分がありませんか？

### タイムスタンプ処理の重複

`BBS::Message` クラスには、こんなプロパティがありました。

```perl
has timestamp => (is => 'ro', default => sub { time });
```

そして `BBS::Thread` クラスにも、作成日時を追加したくなることがあります。スレッドがいつ作られたかを記録したい場合です。

```perl
has created_at => (is => 'ro', default => sub { time });
```

どちらも「作成時刻を自動で記録する」という同じ機能です。今は2つのクラスだけですが、今後クラスが増えるたびに同じコードを書くのは面倒ですし、間違いの元にもなります。

継承を使えばいいのでは？と思うかもしれません。でも、`BBS::Message` と `BBS::Thread` は親子関係にはありません。メッセージはスレッドの子ではないし、スレッドはメッセージの子でもありません。

こういうときに使えるのが「ロール」です。

## ロールとは何か

ロールは、複数のクラスで共有したい機能をまとめたものです。

### 継承とは違う「できること」の共有

継承は「〜の一種である」という関係を表します。たとえば、「AdminUser は User の一種である」という関係です。

一方、ロールは「〜ができる」という能力を表します。たとえば、「タイムスタンプを持つことができる」という能力です。

`BBS::Message` と `BBS::Thread` は親子関係ではありませんが、どちらも「タイムスタンプを持つことができる」という共通の能力を持っています。このような場合に、ロールが役立ちます。

## Moo::Roleを使う

それでは、タイムスタンプ機能をロールとして作ってみましょう。

```perl
package BBS::Role::Timestampable {
    use Moo::Role;

    has created_at => (
        is      => 'ro',
        default => sub { time },
    );

    sub formatted_time {
        my $self = shift;
        return scalar(localtime($self->created_at));
    }
};
```

このロールには、いくつかの重要なポイントがあります。

まず、`use Moo` ではなく `use Moo::Role` を使っています。これがロールを定義するときのおまじないです。

次に、`has` でプロパティを定義しています。`created_at` プロパティは、オブジェクトが作られた時刻を自動的に記録します。

さらに、`sub` でメソッドも定義しています。`formatted_time` メソッドは、タイムスタンプを読みやすい形式に変換します。

ロールはクラスと似ていますが、単独でオブジェクトを作ることはできません。他のクラスに「適用」して使います。

## withでロールを適用する

作ったロールを、`BBS::Message` と `BBS::Thread` に適用してみましょう。

```perl
package BBS::Message {
    use Moo;

    with 'BBS::Role::Timestampable';

    has content => (is => 'ro', required => 1);
    has author  => (is => 'ro', required => 1);

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            $self->formatted_time,
            $self->author,
            $self->content;
    }
};

package BBS::Thread {
    use Moo;

    with 'BBS::Role::Timestampable';

    has title    => (is => 'ro', required => 1);
    has messages => (is => 'ro', default => sub { [] });

    sub add_message {
        my ($self, $message) = @_;
        push @{$self->messages}, $message;
    }

    sub info {
        my $self = shift;
        return sprintf "[%s] %s",
            $self->formatted_time,
            $self->title;
    }
};
```

`with 'BBS::Role::Timestampable';` の1行で、ロールを適用しています。

これにより、`BBS::Message` と `BBS::Thread` の両方に、`created_at` プロパティと `formatted_time` メソッドが追加されます。

実際に使ってみましょう。

```perl
use BBS::Message;
use BBS::Thread;

my $thread = BBS::Thread->new(title => '雑談スレッド');
print $thread->info, "\n";
# [Sun Dec 29 23:04:41 2025] 雑談スレッド

my $msg = BBS::Message->new(content => 'こんにちは！', author => 'nqounet');
print $msg->format, "\n";
# [Sun Dec 29 23:04:41 2025] nqounet: こんにちは！
```

どちらのクラスでも、`formatted_time` メソッドが使えています。タイムスタンプの処理を一箇所にまとめたので、変更が必要になっても、ロールを修正するだけで済みます。

## まとめ

今回は、ロールを使って複数のクラスで共通の機能を共有する方法を学びました。

- 同じコードを複数のクラスに書くのは、保守性が悪い
- ロールは「〜ができる」という能力を共有する仕組みである
- `use Moo::Role` でロールを定義する
- `with` でクラスにロールを適用する
- ロールにはプロパティもメソッドも定義できる

次回は、別のオブジェクトに処理を任せる「委譲」について学びます。
