---
title: "第3回-タスクをファイルに保存する - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - file-io
  - moo
description: "PerlでTaskクラスをMooで設計し、openを使ってファイルに書き込む方法を解説。UTF-8エンコーディングでタスクをテキストファイルに保存します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第3回です。今回は、Taskクラスを設計し、タスクをファイルに保存する処理を実装します。

## 前回の振り返り

前回は、`<STDIN>`を使ってユーザーからの入力を受け取り、対話型のメニューUIを作成しました。

{{< linkcard "/post/perl-todo-cli-02/" >}}

`chomp`で改行を除去し、if文で入力値に応じた処理を分岐しました。今回は、タスクを表すTaskクラスを作成し、データをファイルに永続化します。

## Taskクラスの設計

タスクを管理するために、個々のタスクを表すTaskクラスを作成します。Mooで覚えたオブジェクト指向の知識を活かして、シンプルなクラスを設計しましょう。

```perl
# lib/Task.pm
# Perl 5.40+
# 外部依存: Moo

package Task;
use Moo;

has id => (
    is       => 'ro',
    required => 1,
);

has title => (
    is       => 'ro',
    required => 1,
);

has done => (
    is      => 'rw',
    default => sub { 0 },
);

sub to_line {
    my $self = shift;
    return join("\t", $self->id, $self->done, $self->title);
}

1;
```

このTaskクラスのポイントを解説します。

- `id`はタスクの識別子で、読み取り専用（`ro`）かつ必須である
- `title`はタスクの内容で、こちらも読み取り専用かつ必須である
- `done`は完了フラグで、読み書き可能（`rw`）であり、デフォルトは`0`（未完了）である
- `to_line`メソッドは、タスクをファイル保存用の1行形式に変換する

`to_line`メソッドでは、タブ文字（`\t`）を区切りとして「id」「done」「title」を1行にまとめています。タブ区切りにする理由は、タイトルにスペースが含まれる場合でも正しくパースできるためです。

## openによるファイル書き込み

タスクをファイルに保存するには、Perlの`open`関数を使います。ここでは、3引数形式の`open`を使用します。

```perl
# save_tasks.pl
# Perl 5.40+
# 外部依存: Moo

use strict;
use warnings;
use lib 'lib';
use Task;

my @tasks = (
    Task->new(id => 1, title => '牛乳を買う'),
    Task->new(id => 2, title => 'レポートを書く', done => 1),
);

my $file = 'tasks.txt';

open my $fh, '>:encoding(UTF-8)', $file
    or die "Cannot open $file: $!";

for my $task (@tasks) {
    print $fh $task->to_line . "\n";
}

close $fh;

print "Saved " . scalar(@tasks) . " tasks to $file\n";
```

このコードのポイントを解説します。

- `open my $fh, '>:encoding(UTF-8)', $file`で書き込み用にファイルを開く
- `>`は書き込みモードを表し、ファイルの内容を上書きする
- `:encoding(UTF-8)`でUTF-8エンコーディングを指定する
- `or die`でファイルオープン失敗時にエラーメッセージを表示する
- `print $fh`でファイルハンドルに書き込む
- `close $fh`でファイルを閉じる

`open`の3引数形式（`open FILEHANDLE, MODE, EXPR`）は、2引数形式よりも安全であり、現代のPerlでは推奨される書き方です。

## UTF-8エンコーディングの重要性

日本語のタスクを正しく保存・読み込みするためには、UTF-8エンコーディングの指定が必須です。

`:encoding(UTF-8)`を指定しないと、以下のような問題が発生する可能性があります。

- 日本語が文字化けする
- 異なる環境間でファイルを共有できない
- マルチバイト文字の処理で予期しないエラーが発生する

このシリーズでは一貫してUTF-8を使用します。ファイル操作では常に`:encoding(UTF-8)`を指定する習慣をつけましょう。

## 次回予告

次回は、保存したファイルからタスクを読み込む処理を実装します。`open`の読み込みモードと、データのパースについて学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. **第3回 - タスクをファイルに保存する**（この記事）
4. 第4回 - ファイルからタスクを読み込む（予定）
5. 第5回 - ファイル版の限界とデータベースへの移行（予定）
6. 第6回 - タスクをデータベースに追加する（予定）
7. 第7回 - タスク一覧を表示する（予定）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
