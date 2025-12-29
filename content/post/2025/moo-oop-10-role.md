---
title: "第10回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - moo
  - object-oriented
description: "Moo::Roleで共通機能を定義し、withで複数のクラスに適用する方法を学びます"
---

[@nqounet](https://twitter.com/nqounet)です。

第9回では、Userクラスを作成し、委譲（handles）を使ってメソッドを転送する方法を学びました。「メッセージは投稿者を持っている」という関係を、コンポジションと委譲で表現しましたね。

さて、ここまで作ってきた掲示板を振り返ると、MessageクラスもThreadクラスも「投稿日時」を持っています。第6回で作った`posted_at`プロパティですね。しかし、同じような機能を複数のクラスで別々に定義するのは、コードの重複になってしまいます。

「継承を使えばいいのでは？」と思うかもしれません。確かに、ThreadはMessageを継承しているので、`posted_at`は引き継がれます。しかし、もし継承関係にないクラス同士で同じ機能を共有したい場合はどうでしょうか。

今回は、こうした課題を解決する「Role」という仕組みを学びます。

## Roleとは

Roleとは、複数のクラスに共通する機能をまとめたものです。Roleを使うと、継承関係にないクラス同士でも同じ機能を共有できます。

継承が「親子関係」を表すのに対し、Roleは「合成（コンポジション）」という考え方に基づいています。クラスにRoleを「混ぜ込む」イメージです。

継承とRoleの違いを整理してみましょう。

継承（extends）の特徴は以下の通りです。

- 「AはBの一種である」という関係を表す
- 親クラスは1つしか指定できない
- 親子関係が固定される

Role（with）の特徴は以下の通りです。

- 「Aは〇〇の機能を持つ」という関係を表す
- 複数のRoleを同時に適用できる
- クラス間の継承関係に依存しない

例えば、「タイムスタンプ機能」は、メッセージにもスレッドにも、さらにはユーザー情報にも必要かもしれません。こうした「横断的な機能」をRoleとして切り出すことで、コードの重複を避けられます。

## Moo::Roleで共通機能を定義する

では、実際にRoleを作ってみましょう。Mooでは、`Moo::Role`を使ってRoleを定義します。

MessageとThreadで共通して使える「タイムスタンプ機能」をTimestampable Roleとして切り出します。

```perl
# Timestampable Role（タイムスタンプ機能）
package Timestampable {
    use Moo::Role;
    
    has created_at => (
        is      => 'ro',
        builder => '_build_created_at',
    );
    
    sub _build_created_at {
        return time();
    }
    
    sub formatted_time {
        my $self = shift;
        return scalar localtime($self->created_at);
    }
};

# MessageクラスにRoleを適用
package Message {
    use Moo;
    with 'Timestampable';  # Roleを適用
    
    has author => (is => 'ro', required => 1);
    has body   => (is => 'rw', required => 1);
    
    sub show {
        my $self = shift;
        print '[' . $self->formatted_time . '] ';
        print $self->author . ': ' . $self->body . "\n";
    }
};

# 使い方
my $msg = Message->new(author => '太郎', body => 'こんにちは！');
$msg->show;  # [Sun Dec 29 19:00:00 2024] 太郎: こんにちは！
```

Roleの定義で注目すべき点は`use Moo::Role;`です。これは通常のクラスで使う`use Moo;`の代わりに書きます。

Timestampable Roleには、`created_at`プロパティと`formatted_time`メソッドが定義されています。これらは、このRoleを適用したクラスで使えるようになります。

## withでRoleを適用する

Roleをクラスに適用するには、`with`を使います。上のコードでは`with 'Timestampable';`と書いていますね。この1行を書くだけで、Messageクラスは`created_at`プロパティと`formatted_time`メソッドを持つようになります。まるでMessageクラス自身で定義したかのように使えるのです。

ThreadクラスにもRoleを適用できます。ThreadクラスはMessageを継承していますが、継承とRoleは組み合わせて使うことができます。`extends 'Message';`の後に`with 'Timestampable';`と書けばよいのです。

また、複数のRoleを適用したい場合は、`with 'Timestampable', 'Searchable';`のようにカンマ区切りで指定できます。

## requiresでメソッドを要求する

Roleには、もう1つ便利な機能があります。それが`requires`です。

`requires`を使うと、「このRoleを適用するクラスは、必ずこのメソッドを実装していなければならない」という制約を定義できます。

```perl
package Displayable {
    use Moo::Role;
    
    requires 'to_string';  # to_stringメソッドを要求
    
    sub display {
        my $self = shift;
        print $self->to_string . "\n";
    }
};
```

このRoleを適用するクラスは、`to_string`メソッドを実装していなければなりません。実装していないクラスにRoleを適用しようとすると、エラーになります。

`requires`を使うことで、Roleが正しく動作するために必要なメソッドをクラスに強制できます。これにより、Roleとクラスの契約関係が明確になり、バグを防ぐことができます。

## まとめ

今回は、Moo::Roleを使って共通機能を定義し、`with`で複数のクラスに適用する方法を学びました。

- Roleは複数のクラスに共通する機能をまとめたものである
- Roleは継承とは違い「合成」という考え方に基づく
- `use Moo::Role;`でRoleを定義する
- `with 'Role名'`でRoleをクラスに適用する
- 複数のRoleを同時に適用できる
- `requires`でRoleが期待するメソッドを強制できる

継承は「AはBの一種である」という関係を表すのに対し、Roleは「Aは〇〇の機能を持つ」という関係を表します。どちらもコードの再利用を促進しますが、適用すべき場面が異なります。

特定の機能を複数のクラスで共有したい場合、継承関係を作るよりもRoleを使う方が柔軟で保守しやすいコードになることが多いです。

次回は、多態性（ポリモーフィズム）について学び、管理者と一般ユーザーで異なる振る舞いを実装していきます。お楽しみに！
