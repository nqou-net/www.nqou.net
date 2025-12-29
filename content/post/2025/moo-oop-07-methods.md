---
title: "第7回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - moo
  - object-oriented
description: "Boardクラスを作成し、メソッドで投稿の追加・一覧表示・カウント機能を実装します"
---

[@nqounet](https://twitter.com/nqounet)です。

第6回では、`required`で必須項目を設定し、`default`や`builder`でデフォルト値を設定する方法を学びました。これにより、Messageクラスは「投稿者と本文は必須」「投稿日時は自動設定」という、より実用的なクラスになりましたね。

さて、1つの投稿を表すMessageクラスはできましたが、掲示板にはたくさんの投稿が並びますよね。複数のメッセージをまとめて管理する仕組みが必要です。

今回は、複数のメッセージを管理する「Board（掲示板）」クラスを作り、投稿の追加・一覧表示・投稿数の取得といった機能をメソッドとして実装していきます。

## 掲示板クラスを作ろう

掲示板の役割を考えてみましょう。掲示板は「複数のメッセージを保持する場所」です。新しい投稿を受け付けたり、投稿の一覧を表示したり、全部で何件の投稿があるかを教えてくれたりします。

これをクラスとして表現するなら、Boardクラスは「メッセージの配列」を持ち、それを操作するための「メソッド」を提供すればよいですね。

Mooでは、配列やハッシュをプロパティとして持つ場合、`default => sub { [] }`のように無名サブルーチンで書くのでしたね。これにより、オブジェクトごとに独立した配列が作られます。

## メソッドで機能を追加する

Messageクラスには`show`メソッドがありました。これはメッセージの内容を表示する機能でしたね。

同じように、Boardクラスにも便利な機能をメソッドとして追加していきましょう。掲示板に必要な機能を考えると、以下の3つがあります。

- add_message：新しい投稿を追加する
- show_all：すべての投稿を一覧表示する
- count：投稿の総数を返す

メソッドは、クラスの中で`sub メソッド名 { ... }`と書いて定義します。第1引数には`$self`（そのオブジェクト自身）が渡されるので、`$self->messages`のようにしてオブジェクトのプロパティにアクセスできます。

では、Boardクラスを実装してみましょう。

```perl
# Boardクラス
package Board {
    use Moo;
    
    has messages => (is => 'rw', default => sub { [] });
    
    sub add_message {
        my ($self, $message) = @_;
        push @{$self->messages}, $message;
    }
    
    sub show_all {
        my $self = shift;
        for my $msg (@{$self->messages}) {
            $msg->show;
        }
    }
    
    sub count {
        my $self = shift;
        return scalar @{$self->messages};
    }
};
```

それぞれのメソッドを見てみましょう。

`add_message`は、受け取ったメッセージオブジェクトを`messages`配列に追加します。`push @{$self->messages}, $message`で、配列の末尾に新しい要素を追加しています。

`show_all`は、`messages`配列の中身を順番に取り出して、それぞれの`show`メソッドを呼び出します。Messageクラスが持っている機能を活用しているわけです。

`count`は、`messages`配列の要素数を返します。`scalar`を付けることで、配列の長さを数値として取得できます。

## 実際に動かしてみよう

では、MessageクラスとBoardクラスを組み合わせて動かしてみましょう。

```perl
# Messageクラス（第6回で作成したもの）
package Message {
    use Moo;
    
    has author    => (is => 'ro', required => 1);
    has body      => (is => 'rw', required => 1);
    has posted_at => (is => 'ro', builder => '_build_posted_at');
    
    sub _build_posted_at {
        my $self = shift;
        return time();
    }
    
    sub show {
        my $self = shift;
        print $self->author . ': ' . $self->body . "\n";
    }
};

# Boardクラス
package Board {
    use Moo;
    
    has messages => (is => 'rw', default => sub { [] });
    
    sub add_message {
        my ($self, $message) = @_;
        push @{$self->messages}, $message;
    }
    
    sub show_all {
        my $self = shift;
        for my $msg (@{$self->messages}) {
            $msg->show;
        }
    }
    
    sub count {
        my $self = shift;
        return scalar @{$self->messages};
    }
};

# 掲示板を作成
my $board = Board->new;

# メッセージを投稿
$board->add_message(Message->new(author => '太郎', body => 'こんにちは！'));
$board->add_message(Message->new(author => '花子', body => 'はじめまして！'));
$board->add_message(Message->new(author => '太郎', body => '今日はいい天気ですね'));

# 投稿数を確認
print "投稿数: " . $board->count . "\n";

# 一覧表示
$board->show_all;
```

実行すると、以下のように表示されます。

```
投稿数: 3
太郎: こんにちは！
花子: はじめまして！
太郎: 今日はいい天気ですね
```

掲示板らしくなってきましたね。`$board->add_message(...)`で投稿を追加し、`$board->show_all`で一覧表示、`$board->count`で投稿数を取得できます。

ここで注目してほしいのは、BoardクラスはMessageクラスの中身を知らなくても動作することです。Boardクラスは「`show`メソッドを持つオブジェクト」を受け取って、それを配列に保存し、必要なときに`show`を呼び出しているだけです。

このように、クラスを組み合わせて使うことで、それぞれの責任を分離でき、コードがシンプルになります。Messageクラスは「1つの投稿を表現すること」に責任を持ち、Boardクラスは「複数の投稿を管理すること」に責任を持つのです。

## まとめ

今回は、複数のメッセージを管理するBoardクラスを作成しました。

- 配列をプロパティとして持つには`default => sub { [] }`を使う
- メソッドは`sub メソッド名 { ... }`で定義する
- 第1引数の`$self`でオブジェクト自身にアクセスできる
- `add_message`で投稿を追加、`show_all`で一覧表示、`count`で投稿数を取得できる
- クラスを組み合わせることで、責任を分離できる

メソッドを追加することで、オブジェクトに「できること」を増やしていけます。プロパティが「オブジェクトが持つデータ」なら、メソッドは「オブジェクトが持つ機能」です。

次回は、掲示板にスレッド機能を追加します。Threadクラスを作る際に、Messageクラスの機能を引き継ぐ「継承」という概念を学びましょう。
