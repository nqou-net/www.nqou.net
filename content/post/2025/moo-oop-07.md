---
title: "第7回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - object-oriented
  - programming
description: "Threadクラスを作成し、メッセージをまとめる機能を実装します"
---

[@nqounet](https://twitter.com/nqounet)です。

前回は、継承を使って一般ユーザーと管理者ユーザーを実装しました。`extends` の1行で親クラスの機能を引き継げることが分かりましたね。

今回は、メッセージをまとめて管理するスレッド機能を作っていきます。その過程で、「オブジェクトの集約」という概念を学びましょう。

## スレッドって何だろう

チャットアプリでは、メッセージがどんどん流れていきます。でも、話題ごとにメッセージをまとめたいことがありますよね。

たとえば、「自己紹介スレッド」「質問スレッド」「雑談スレッド」のように、話題ごとにメッセージを分けて管理できると便利です。

### メッセージをまとめる箱

スレッドは、複数のメッセージをまとめる「箱」のようなものです。

- 1つのスレッドは、複数のメッセージを持つ
- スレッドにはタイトルがある
- 新しいメッセージを追加できる

この「複数のオブジェクトを持つ」という関係を、オブジェクト指向では「集約」と呼びます。

## Threadクラスを作る

それでは、スレッドを表す `BBS::Thread` クラスを作ってみましょう。

```perl
package BBS::Thread {
    use Moo;

    has title    => (is => 'ro', required => 1);
    has messages => (is => 'ro', default => sub { [] });

    sub add_message {
        my ($self, $message) = @_;
        push @{$self->messages}, $message;
    }

    sub count {
        my $self = shift;
        return scalar @{$self->messages};
    }

    sub list {
        my $self = shift;
        my @result;
        for my $msg (@{$self->messages}) {
            push @result, $msg->format;
        }
        return @result;
    }
};
```

このクラスには、いくつかの新しい要素があります。順番に見ていきましょう。

### messagesプロパティ

```perl
has messages => (is => 'ro', default => sub { [] });
```

`messages` プロパティのデフォルト値は `sub { [] }` です。これは「空の配列への参照」を返す無名サブルーチンです。

なぜ `default => []` ではなく `default => sub { [] }` と書くのでしょうか。

Mooでは、デフォルト値が配列やハッシュの場合、サブルーチンで包む必要があります。こうしないと、すべてのオブジェクトが同じ配列を共有してしまい、おかしなことになってしまいます。

`sub { [] }` と書くことで、オブジェクトが作られるたびに新しい配列が生成されます。

## メッセージを追加するメソッド

```perl
sub add_message {
    my ($self, $message) = @_;
    push @{$self->messages}, $message;
}
```

`add_message` メソッドは、スレッドにメッセージを追加します。

引数で受け取った `$message` を、`messages` 配列に `push` しています。`$self->messages` は配列への参照なので、`@{...}` でデリファレンスしてから `push` します。

これが「集約」の実装です。`BBS::Thread` オブジェクトの中に、複数の `BBS::Message` オブジェクトを配列として持っています。

## スレッドにメッセージを投稿する

それでは、実際にスレッドを作って、メッセージを投稿してみましょう。

```perl
use BBS::Thread;
use BBS::Message;

# スレッドを作成
my $thread = BBS::Thread->new(title => '自己紹介スレッド');

# メッセージを追加
$thread->add_message(
    BBS::Message->new(content => 'はじめまして！', author => 'nqounet')
);
$thread->add_message(
    BBS::Message->new(content => 'よろしくお願いします', author => 'perl_lover')
);
$thread->add_message(
    BBS::Message->new(content => 'Perl大好きです！', author => 'moo_fan')
);

# メッセージ数を確認
print "メッセージ数: ", $thread->count, "\n";
# メッセージ数: 3

# すべてのメッセージを表示
for my $line ($thread->list) {
    print $line, "\n";
}
# [Sun Dec 29 23:04:41 2025] nqounet: はじめまして！
# [Sun Dec 29 23:04:41 2025] perl_lover: よろしくお願いします
# [Sun Dec 29 23:04:41 2025] moo_fan: Perl大好きです！
```

`BBS::Thread` オブジェクトが、複数の `BBS::Message` オブジェクトを内部に持っています。

`add_message` でメッセージを追加し、`count` でメッセージ数を確認し、`list` ですべてのメッセージを整形して取得できます。

これが「オブジェクトの集約」です。あるオブジェクト（スレッド）が、別のオブジェクト（メッセージ）を複数持つという関係を、配列を使って実現しています。

## まとめ

今回は、スレッド機能を追加しながら、オブジェクトの集約について学びました。

- スレッドは複数のメッセージをまとめる「箱」である
- 「集約」とは、あるオブジェクトが別のオブジェクトを複数持つ関係である
- 配列への参照をプロパティとして持つことで、集約を実現できる
- `default => sub { [] }` で、オブジェクトごとに独立した配列を持たせる

次回は、さらに機能を追加していきます。
