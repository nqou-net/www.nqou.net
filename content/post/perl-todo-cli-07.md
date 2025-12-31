---
title: "第7回-タスク一覧を表示する（Read） - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - dbi
  - crud
description: "Perl DBIでSELECT文を使ってデータベースからデータを取得。全件取得とWHERE句による条件フィルタ、fetchrow_hashrefの使い方を解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第7回です。今回は、データベースからタスクを取得するSELECT文について学び、Taskクラスに`find_all`メソッドを実装します。

## 前回の振り返り

前回は、タスクをデータベースに追加するINSERT文について学び、Taskクラスに`save`メソッドを実装しました。

{{< linkcard "/post/perl-todo-cli-06/" >}}

`prepare`と`execute`でSQL文を実行し、`last_insert_id`で自動採番されたIDを取得する方法を学びました。今回は、保存したタスクを取得する方法を学びます。

## CRUDの「R」- Read

前回、データベース操作の基本「CRUD」について説明しました。

- **C**reate（作成）: データを追加する
- **R**ead（読み取り）: データを取得する
- **U**pdate（更新）: データを変更する
- **D**elete（削除）: データを削除する

今回は「R」、Read操作を実装します。SQLでは`SELECT`文を使ってデータを取得します。

## SELECT文で全件取得

まず、tasksテーブルからすべてのタスクを取得してみましょう。

```perl
# select_all.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $sth = $dbh->prepare(<<'SQL');
SELECT * FROM tasks
SQL

$sth->execute();

while (my $row = $sth->fetchrow_hashref) {
    print "[$row->{id}] $row->{title} (done: $row->{done})\n";
}
```

このコードのポイントを解説します。

- `SELECT * FROM tasks`は、tasksテーブルの全カラム（`*`）を取得する
- `$sth->execute()`でSQL文を実行する（プレースホルダがないため引数なし）
- `$sth->fetchrow_hashref`は、1行分のデータをハッシュリファレンスで返す
- カラム名がハッシュのキーになる（`$row->{id}`、`$row->{title}`など）
- `while`ループで全行を順番に取得する
- すべての行を取得すると`fetchrow_hashref`は`undef`を返し、ループが終了する

`fetchrow_hashref`は、カラム名でデータにアクセスできるため、コードの可読性が高くなります。

## WHERE句による条件フィルタ

すべてのタスクではなく、未完了のタスクだけを取得したい場合は、`WHERE`句を使います。

```perl
# select_pending.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $sth = $dbh->prepare(<<'SQL');
SELECT * FROM tasks WHERE done = 0
SQL

$sth->execute();

print "=== 未完了のタスク ===\n";
while (my $row = $sth->fetchrow_hashref) {
    print "[$row->{id}] $row->{title}\n";
}
```

このコードのポイントを解説します。

- `WHERE done = 0`で、`done`カラムが`0`（未完了）の行だけを取得する
- データベース側でフィルタするため、ファイルベースのように全件読み込んでからフィルタする必要がない
- データ量が多くても効率的に処理できる

ファイルベースでは、すべてのタスクを読み込んでからPerlでフィルタする必要がありました。データベースを使うことで、必要なデータだけを効率的に取得できます。

## Taskクラスのfind_allメソッド

ここまでの知識を使って、Taskクラスに`find_all`クラスメソッドを追加しましょう。このメソッドは、全タスクまたは未完了タスクを取得し、Taskオブジェクトの配列リファレンスとして返します。

```perl
# lib/Task.pm に追加
# Perl 5.40+
# 外部依存: Moo, DBI, DBD::SQLite

sub find_all {
    my $class = shift;
    my %args  = @_;

    my $dbh = DB::get_dbh();

    my $sql = 'SELECT * FROM tasks';
    if ($args{pending_only}) {
        $sql .= ' WHERE done = 0';
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my @tasks;
    while (my $row = $sth->fetchrow_hashref) {
        push @tasks, $class->new(
            id    => $row->{id},
            title => $row->{title},
            done  => $row->{done},
        );
    }

    return \@tasks;
}
```

このメソッドのポイントを解説します。

- `find_all`はクラスメソッドとして定義する（第一引数が`$class`）
- `%args`で名前付き引数を受け取り、`pending_only`オプションをサポートする
- `pending_only`が真の場合、`WHERE done = 0`を追加する
- 各行を`fetchrow_hashref`で取得し、Taskオブジェクトを生成する
- `push @tasks`で配列に追加し、最後に配列リファレンスを返す

これにより、以下のようにタスク一覧を取得できるようになります。

```perl
use Task;
use DB;

# 全タスクを取得
my $all_tasks = Task->find_all();
for my $task (@$all_tasks) {
    my $status = $task->done ? '✓' : ' ';
    print "[$status] $task->title\n";
}

# 未完了タスクのみ取得
my $pending_tasks = Task->find_all(pending_only => 1);
print "\n未完了: " . scalar(@$pending_tasks) . "件\n";
```

## 次回予告

次回は、タスクを完了にするUPDATE文（Update操作）を実装します。`done`フラグを更新し、タスクの完了状態を変更する方法を学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. [第5回 - ファイル版の限界とデータベースへの移行](/post/perl-todo-cli-05/)
6. [第6回 - タスクをデータベースに追加する](/post/perl-todo-cli-06/)
7. **第7回 - タスク一覧を表示する**（この記事）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
