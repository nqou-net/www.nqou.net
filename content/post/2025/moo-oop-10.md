---
title: "第10回-Mooで覚えるオブジェクト指向プログラミング"
draft: true
tags:
  - perl
  - object-oriented
  - programming
description: "メソッド修飾子を使って、既存の処理を拡張します"
---

[@nqounet](https://twitter.com/nqounet)です。

前回は、委譲を使ってオブジェクト間の責任を分離する方法を学びました。`handles` オプションで、`author` プロパティから `name` メソッドを委譲しましたね。

今回は、既存のメソッドを変更せずに処理を追加する「メソッド修飾子」について学びましょう。

## 既存の処理に何かを追加したい

掲示板アプリの開発が進んできました。`BBS::Message` クラスでメッセージを投稿できるようになっています。

ところが、実際に運用を始めると、いくつかの要望が出てきました。

- 空のメッセージを投稿できないようにしたい
- メッセージが投稿されたらログに記録したい

これらの機能を追加するには、どうすればよいでしょうか？

もちろん、既存のメソッドを直接書き換えることもできます。でも、元のコードを変更すると、他の部分に影響が出るかもしれません。

こういうときに便利なのが「メソッド修飾子」です。

## beforeで事前チェック

`before` は、メソッドが実行される「前」に処理を追加するための仕組みです。

バリデーション（入力チェック）のように、「この処理が始まる前に確認しておきたい」という場面で使います。

### 投稿前のバリデーション

空のメッセージを投稿できないようにしてみましょう。`BUILD` メソッドに `before` を適用して、`content` が空でないかチェックします。

```perl
package BBS::Message {
    use Moo;

    with 'BBS::Role::Timestampable';

    has content => (is => 'ro', required => 1);
    has author  => (
        is       => 'ro',
        required => 1,
        handles  => { author_name => 'name' },
    );

    before BUILD => sub {
        my ($self, $args) = @_;
        die "content は空にできません\n"
            if !defined $args->{content} || $args->{content} eq '';
    };

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            $self->formatted_time,
            $self->author_name,
            $self->content;
    }
};

# 使用例
my $user = BBS::User->new(name => 'nqounet');

# 正常なメッセージ
my $msg = BBS::Message->new(content => 'こんにちは！', author => $user);
print $msg->format, "\n";

# 空のメッセージはエラー
my $empty = BBS::Message->new(content => '', author => $user);
# => content は空にできません
```

`before BUILD => sub { ... }` の部分がメソッド修飾子です。

`BUILD` は、オブジェクトが作られた直後に自動的に呼ばれる特別なメソッドです。`before` を付けることで、その「直前」に処理を追加しています。

この例では、`content` が空文字列の場合に `die` でエラーを発生させています。元の `BUILD` メソッド（今回は定義していませんが）を変更する必要はありません。

## afterで事後処理

`after` は、メソッドが実行された「後」に処理を追加するための仕組みです。

ログ出力や通知のように、「この処理が終わった後に何かしたい」という場面で使います。

### 投稿後のログ出力

メッセージが作成されたことをログに記録してみましょう。

```perl
package BBS::Message {
    use Moo;

    with 'BBS::Role::Timestampable';

    has content => (is => 'ro', required => 1);
    has author  => (
        is       => 'ro',
        required => 1,
        handles  => { author_name => 'name' },
    );

    before BUILD => sub {
        my ($self, $args) = @_;
        die "content は空にできません\n"
            if !defined $args->{content} || $args->{content} eq '';
    };

    after BUILD => sub {
        my ($self, $args) = @_;
        warn sprintf "[LOG] メッセージ作成: %s by %s\n",
            $self->content,
            $self->author_name;
    };

    sub format {
        my $self = shift;
        return sprintf "[%s] %s: %s",
            $self->formatted_time,
            $self->author_name,
            $self->content;
    }
};

# 使用例
my $user = BBS::User->new(name => 'nqounet');
my $msg  = BBS::Message->new(content => 'こんにちは！', author => $user);
# => [LOG] メッセージ作成: こんにちは！ by nqounet
```

`after BUILD => sub { ... }` で、オブジェクト作成後にログを出力しています。

`warn` を使っているのは、ログとして標準エラー出力に書き出すためです。本番環境では、専用のログモジュールを使うことが多いですが、ここではシンプルに `warn` を使っています。

## 元のコードを変えずに拡張できる

メソッド修飾子の最大の利点は、既存のコードを変更せずに機能を追加できることです。

- 元のメソッドの処理はそのまま維持される
- バリデーションやログ出力などの「横断的な関心事」を分離できる
- 問題が発生しても、修飾子を外せば元に戻せる

特に大きなプロジェクトでは、1つのメソッドを複数の人が修正すると混乱が起きやすいです。メソッド修飾子を使えば、お互いの変更が衝突するリスクを減らせます。

また、ロールと組み合わせることもできます。たとえば、ログ出力の機能をロールとして定義しておけば、複数のクラスで同じログ処理を適用できます。

## まとめ

今回は、メソッド修飾子を使って既存の処理を拡張する方法を学びました。

- `before` — メソッドの実行前に処理を追加
- `after` — メソッドの実行後に処理を追加
- 元のメソッドを変更せずに機能を追加できる
- バリデーションやログ出力に便利

次回は、オブジェクトが作られるときと消えるときに自動で呼ばれる `BUILD` と `DEMOLISH` について学びます。
