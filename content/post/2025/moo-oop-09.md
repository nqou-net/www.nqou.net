---
title: "第9回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - object-oriented
  - programming
description: "委譲を使って、オブジェクト間の責任を適切に分離します"
---

[@nqounet](https://twitter.com/nqounet)です。

前回は、ロールを使って複数のクラスで共通の機能を共有する方法を学びました。`BBS::Role::Timestampable` を作り、`BBS::Message` と `BBS::Thread` の両方に適用しましたね。

今回は、別のオブジェクトに処理を任せる「委譲」について学びましょう。

## Messageの中でUserを使う

掲示板のメッセージには、投稿者の情報が必要です。今までは `author` プロパティに文字列で名前を入れていました。

でも、投稿者にはもっと多くの情報があるはずです。たとえば、表示名だけでなく、メールアドレスやプロフィールなどです。こういった情報をまとめて管理するために、`User` クラスを作ってみましょう。

### オブジェクトをプロパティに

プロパティには、文字列や数値だけでなく、オブジェクトも入れることができます。

```perl
package BBS::User {
    use Moo;

    has name  => (is => 'ro', required => 1);
    has email => (is => 'ro');
};

package BBS::Message {
    use Moo;

    with 'BBS::Role::Timestampable';

    has content => (is => 'ro', required => 1);
    has author  => (is => 'ro', required => 1);  # Userオブジェクト

    sub author_name {
        my $self = shift;
        return $self->author->name;
    }

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            $self->formatted_time,
            $self->author_name,
            $self->content;
    }
};

# 使用例
my $user = BBS::User->new(name => 'nqounet', email => 'nqounet@example.com');
my $msg  = BBS::Message->new(content => 'こんにちは！', author => $user);

print $msg->author_name, "\n";  # nqounet
print $msg->format, "\n";
```

`author` プロパティに `BBS::User` オブジェクトを入れています。`author_name` メソッドでは、`$self->author->name` のように、`author` プロパティを通じて `User` オブジェクトの `name` を取得しています。

これは動きますが、少し面倒な点があります。メッセージから投稿者の名前を取得するたびに、`$msg->author_name` や `$msg->author->name` と書く必要があります。

## 委譲とは何か

ここで「委譲」という考え方が役立ちます。

### 別のオブジェクトにお任せ

委譲とは、あるオブジェクトへのメソッド呼び出しを、別のオブジェクトに転送する仕組みです。

先ほどの例で言えば、`$msg->author_name` が呼ばれたとき、内部的に `$msg->author->name` を呼び出す、という処理を自動化できます。

委譲を使うと、オブジェクトの内部構造を隠しつつ、必要なメソッドだけを外部に公開できます。利用者は `Message` オブジェクトだけを意識すればよく、`User` オブジェクトの存在を知らなくても済みます。

## handlesの使い方

Mooでは、`handles` オプションを使って委譲を簡単に設定できます。

`handles` は `has` でプロパティを定義するときに指定します。配列リファレンスで委譲するメソッドを列挙するか、ハッシュリファレンスで別名を付けることができます。

- `handles => ['name']` — `name` メソッドをそのまま委譲
- `handles => { author_name => 'name' }` — `author_name` として `name` を委譲

## author_nameを委譲する

それでは、委譲を使って `BBS::Message` を書き直してみましょう。

```perl
package BBS::User {
    use Moo;

    has name  => (is => 'ro', required => 1);
    has email => (is => 'ro');
};

package BBS::Message {
    use Moo;

    with 'BBS::Role::Timestampable';

    has content => (is => 'ro', required => 1);
    has author  => (
        is       => 'ro',
        required => 1,
        handles  => { author_name => 'name' },
    );

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            $self->formatted_time,
            $self->author_name,
            $self->content;
    }
};

# 使用例
my $user = BBS::User->new(name => 'nqounet', email => 'nqounet@example.com');
my $msg  = BBS::Message->new(content => 'こんにちは！', author => $user);

print $msg->author_name, "\n";  # nqounet
print $msg->format, "\n";
```

変更点は `author` プロパティの定義部分です。`handles => { author_name => 'name' }` を追加しました。

これにより、`$msg->author_name` を呼び出すと、自動的に `$msg->author->name` が呼び出されます。`author_name` メソッドを自分で書く必要がなくなりました。

ハッシュリファレンスを使っているのは、`Message` 側では `author_name` という名前で呼び出したいからです。もし `name` という名前でよければ、`handles => ['name']` と配列リファレンスで書くこともできます。

## まとめ

今回は、委譲を使ってオブジェクト間の責任を分離する方法を学びました。

- プロパティには、オブジェクトを入れることができる
- 委譲は、メソッド呼び出しを別のオブジェクトに転送する仕組みである
- `handles` オプションで委譲を設定する
- ハッシュリファレンスで別名を付けて委譲できる
- 委譲を使うと、内部構造を隠して必要なメソッドだけを公開できる

次回は、型制約を使ってプロパティに入る値をチェックする方法を学びます。
