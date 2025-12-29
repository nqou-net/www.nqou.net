---
title: "第9回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - moo
  - object-oriented
description: "Userクラスを作成し、handles（委譲）でメソッドを転送する方法を学びます"
---

[@nqounet](https://twitter.com/nqounet)です。

第8回では、継承を使ってMessageクラスからThreadクラスを作成しました。「スレッドはメッセージの一種である」という関係を、`extends`で表現しましたね。

さて、ここまでの掲示板では、投稿者の情報を「太郎」「花子」といった単なる文字列で管理していました。しかし、実際の掲示板サービスを考えると、ユーザーには名前だけでなく、IDやメールアドレスなど様々な情報がありますよね。

今回は、ユーザー情報を管理するUserクラスを作成し、「委譲（handles）」という新しい概念を学びます。継承とは異なるコード再利用の仕組みを見ていきましょう。

## Userクラスを作ろう

まずは、ユーザー情報を管理するUserクラスを作ります。ユーザーに必要な情報を考えてみましょう。

- id（ユーザーID）：一意に識別するための番号
- name（表示名）：掲示板に表示される名前
- email（メールアドレス）：連絡先

これらをMooで実装すると、以下のようになります。

```perl
# Userクラス
package User {
    use Moo;
    has id    => (is => 'ro', required => 1);
    has name  => (is => 'rw', required => 1);
    has email => (is => 'rw');
};

# Messageクラス（委譲を使用）
package Message {
    use Moo;
    has author => (
        is       => 'ro',
        required => 1,
        handles  => [qw(name)],  # author->nameをnameで呼べる
    );
    has body      => (is => 'rw', required => 1);
    has posted_at => (is => 'ro', builder => '_build_posted_at');
    
    sub _build_posted_at { return time(); }
    
    sub show {
        my $self = shift;
        print $self->name . ': ' . $self->body . "\n";
    }
};

# 使い方
my $user = User->new(id => 1, name => '太郎', email => 'taro@example.com');
my $msg = Message->new(author => $user, body => 'こんにちは！');

print $msg->name . "\n";  # 委譲により「太郎」が表示される
$msg->show;               # 太郎: こんにちは！
```

このコードには新しい概念がいくつか含まれています。順番に見ていきましょう。

## MessageにUserを持たせる

まず注目してほしいのは、Messageクラスの`author`属性です。以前は`author => '太郎'`のように文字列を渡していましたが、今回は`author => $user`のようにUserオブジェクトを渡しています。

これは「コンポジション（合成）」と呼ばれる関係です。MessageオブジェクトがUserオブジェクトを「持っている」状態です。第8回で学んだ継承が「〜は〇〇の一種である」という関係だったのに対し、コンポジションは「〜は〇〇を持っている」という関係を表します。

投稿者の情報が必要になったとき、`$msg->author->name`のように、`author`を経由してUserオブジェクトのプロパティにアクセスできます。しかし、毎回`->author->`と書くのは少し面倒ですよね。

## 委譲（handles）とは

そこで登場するのが「委譲」です。委譲とは、あるオブジェクトへのメソッド呼び出しを、別のオブジェクトに転送する仕組みです。

Mooでは、`handles`オプションを使って委譲を設定できます。上のコードをもう一度見てみましょう。

```perl
has author => (
    is       => 'ro',
    required => 1,
    handles  => [qw(name)],  # author->nameをnameで呼べる
);
```

`handles => [qw(name)]`という部分がポイントです。これは「`name`メソッドが呼ばれたら、`author`オブジェクトの`name`メソッドに転送してね」という意味です。

委譲を設定すると、`$msg->author->name`と書かなくても、`$msg->name`だけで投稿者の名前を取得できます。まるでMessageクラス自身が`name`メソッドを持っているかのように振る舞うのです。

`show`メソッドの中でも`$self->name`と書いていますが、これは委譲のおかげで`$self->author->name`と同じ結果になります。コードがスッキリして読みやすくなりましたね。

## 継承と委譲の使い分け

ここで、継承と委譲の違いを整理しておきましょう。

継承（extends）は「〜は〇〇の一種である（is-a関係）」を表します。

- スレッドはメッセージの一種である（Thread is a Message）
- 親クラスのすべてのプロパティとメソッドを引き継ぐ
- 親子関係が固定される

委譲（handles）は「〜は〇〇を持つ（has-a関係）」を表します。

- メッセージは投稿者（ユーザー）を持つ（Message has a User）
- 必要なメソッドだけを転送できる
- オブジェクトの組み合わせが柔軟

使い分けの目安としては、「BはAの一種である」と自然に言えるなら継承、「BはAを持っている」と言える方がしっくりくるなら委譲を使います。

今回の例で考えると、「メッセージはユーザーの一種である」とは言いませんよね。「メッセージはユーザー（投稿者）を持っている」の方が自然です。だから継承ではなく委譲を使いました。

## まとめ

今回は、Userクラスを作成し、委譲（handles）でメソッドを転送する方法を学びました。

- Userクラスでユーザー情報（id、name、email）を管理する
- MessageがUserを持つのはコンポジション（has-a関係）である
- `handles`で指定したメソッドは別のオブジェクトに転送される
- 委譲により`$msg->author->name`を`$msg->name`と書ける
- 継承は「is-a関係」、委譲は「has-a関係」で使い分ける

継承と委譲は、どちらもコードの再利用を促進する仕組みですが、適用すべき場面が異なります。「AはBの一種」なら継承、「AはBを持つ」なら委譲。この使い分けを意識することで、より自然で保守しやすいコードが書けるようになります。

次回は、掲示板にさらなる機能を追加していきます。お楽しみに！
