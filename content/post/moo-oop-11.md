---
title: "第11回-「持っている」ものに仕事を任せる - Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - moo
  - delegation
description: "クラスが大きくなりすぎてメソッドだらけ…。そんなとき、handlesを使えば属性として持っているオブジェクトにメソッド呼び出しを委譲できます。クラスをスリムに保つ委譲のテクニックを学びましょう。"
---

[@nqounet](https://x.com/nqounet)です。

「Mooで覚えるオブジェクト指向プログラミング」シリーズの第11回です。

## 前回の振り返り

前回は、継承関係にないクラス間で振る舞いを共有する**ロール**を学びました。

{{< linkcard "/moo-oop-10/" >}}

`Moo::Role`で定義したロールを`with`で適用することで、MessageにもUserにも同じ機能を追加できましたね。

今回は、属性として持っているオブジェクトに仕事を任せる**委譲（delegation）**を学びます。

## 問題：クラスが肥大化してメソッドだらけ

掲示板アプリが成長して、メッセージの一覧を管理する機能が必要になりました。Boardクラスに、メッセージの追加・取得・件数取得などのメソッドを実装してみます。

```perl
package Board {
    use Moo;

    has messages => (is => 'ro', default => sub { [] });

    sub add_message {
        my ($self, $msg) = @_;
        push @{$self->messages}, $msg;
    }

    sub get_message {
        my ($self, $index) = @_;
        return $self->messages->[$index];
    }

    sub message_count {
        my $self = shift;
        return scalar @{$self->messages};
    }

    sub all_messages {
        my $self = shift;
        return @{$self->messages};
    }

    # ... 掲示板のビジネスロジック ...
    # ... さらにメソッドが増えていく ...
};
```

Boardクラスは掲示板としてのビジネスロジックを持つべきですが、メッセージ一覧の管理（配列操作のラッパー）で埋め尽くされています。

- メッセージ一覧の操作メソッドが増えるたびにBoardが肥大化する
- 「掲示板」の本質的なロジックが埋もれてしまう
- 他のクラスでもメッセージ一覧を使いたいとき、同じコードを書く羽目になる

## 解決策：メッセージ一覧を別クラスに分離

まず、メッセージ一覧を専用のクラスに切り出しましょう。

```perl
package MessageList {
    use Moo;

    has items => (is => 'ro', default => sub { [] });

    sub add {
        my ($self, $msg) = @_;
        push @{$self->items}, $msg;
    }

    sub get {
        my ($self, $index) = @_;
        return $self->items->[$index];
    }

    sub count {
        my $self = shift;
        return scalar @{$self->items};
    }

    sub all {
        my $self = shift;
        return @{$self->items};
    }
};

package Board {
    use Moo;

    has message_list => (
        is      => 'ro',
        default => sub { MessageList->new },
    );

    # メッセージ一覧の操作は message_list に委ねる
};

my $board = Board->new;
$board->message_list->add('こんにちは！');
$board->message_list->add('お元気ですか？');
print $board->message_list->count . "件\n";  # 2件
```

これでMessageListクラスに一覧管理の責務を移せました。しかし、毎回`$board->message_list->add(...)`と書くのは少し面倒です。`$board->add(...)`と書けたら便利ですよね。

ここで登場するのが**handles**です。

## 解決策：handlesで委譲してスッキリ

`handles`オプションを使うと、属性が持つオブジェクトのメソッドを、あたかも自分のメソッドのように呼び出せるようになります。

```perl
package MessageList {
    use Moo;

    has items => (is => 'ro', default => sub { [] });

    sub add {
        my ($self, $msg) = @_;
        push @{$self->items}, $msg;
    }

    sub get {
        my ($self, $index) = @_;
        return $self->items->[$index];
    }

    sub count {
        my $self = shift;
        return scalar @{$self->items};
    }

    sub all {
        my $self = shift;
        return @{$self->items};
    }
};

package Board {
    use Moo;

    has message_list => (
        is      => 'ro',
        default => sub { MessageList->new },
        handles => [qw(add get count all)],  # 委譲！
    );
};

my $board = Board->new;
$board->add('こんにちは！');       # $board->message_list->add(...) と同じ
$board->add('お元気ですか？');
print $board->count . "件\n";      # 2件
print $board->get(0) . "\n";       # こんにちは！
```

`handles => [qw(add get count all)]`と書くと、Boardクラスに`add`、`get`、`count`、`all`というメソッドが自動生成されます。これらのメソッドを呼び出すと、内部で`message_list`属性のオブジェクトに処理を**委譲**します。

- `$board->add($msg)`は`$board->message_list->add($msg)`と同じ動作
- `$board->count`は`$board->message_list->count`と同じ動作

これにより、Boardクラスはスリムなまま、MessageListの機能をそのまま使えるようになります。

ちなみに、メソッド名を変えたい場合はハッシュリファレンスで指定できます。

```perl
has message_list => (
    is      => 'ro',
    default => sub { MessageList->new },
    handles => {
        add_message   => 'add',    # $board->add_message は message_list->add を呼ぶ
        message_count => 'count',  # $board->message_count は message_list->count を呼ぶ
    },
);
```

## まとめ

- `handles`オプションで、属性のオブジェクトにメソッド呼び出しを委譲できる
- 配列形式`handles => [qw(method1 method2)]`で同名のメソッドを委譲
- ハッシュ形式`handles => { new_name => 'original_name' }`でメソッド名を変更して委譲
- 委譲により、クラスの肥大化を防ぎ、責務を適切に分離できる

## 次回予告

次回は、属性に不正な値が入ることを防ぐ**型制約（isa）**を学びます。「いいね数に文字列が入ってしまった」というバグを未然に防ぐ方法を紹介します。シリーズ最終回です。お楽しみに。
