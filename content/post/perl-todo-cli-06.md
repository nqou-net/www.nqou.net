---
title: "第6回-タスクをデータベースに追加する（Create） - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - dbi
  - crud
description: "Perl DBIでINSERT文を使ってSQLiteデータベースにレコードを追加。prepareとexecuteの使い方、last_insert_idでIDを取得する方法を解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第6回です。今回は、タスクをデータベースに追加するINSERT文について学び、Taskクラスに`save`メソッドを実装します。

## 前回の振り返り

前回は、ファイルベースのデータ管理の限界を確認し、SQLiteデータベースへの移行を始めました。

{{< linkcard "/post/perl-todo-cli-05/" >}}

DB.pmにSingletonパターンでDBハンドルを管理する仕組みを作成し、CREATE TABLEでtasksテーブルを作成しました。今回は、このテーブルにデータを追加する方法を学びます。

## CRUDの「C」- Create

データベース操作の基本は「CRUD」と呼ばれます。

- **C**reate（作成）: データを追加する
- **R**ead（読み取り）: データを取得する
- **U**pdate（更新）: データを変更する
- **D**elete（削除）: データを削除する

今回は最初の「C」、Create操作を実装します。SQLでは`INSERT`文を使ってデータを追加します。

## prepareとexecute

DBIでSQL文を実行する際は、`prepare`と`execute`の2段階で処理します。

```perl
# insert_task.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

# SQL文を準備
my $sth = $dbh->prepare(<<'SQL');
INSERT INTO tasks (title, done) VALUES (?, ?)
SQL

# 値をバインドして実行
$sth->execute('牛乳を買う', 0);

print "Task inserted successfully.\n";
```

このコードのポイントを解説します。

- `$dbh->prepare`でSQL文を準備し、ステートメントハンドル（`$sth`）を取得する
- `?`はプレースホルダと呼ばれ、実行時に値が埋め込まれる位置を示す
- `$sth->execute`でプレースホルダに値をバインドし、SQL文を実行する
- プレースホルダを使うことで、SQLインジェクション攻撃を防ぐことができる

`prepare`と`execute`を分けることには、パフォーマンス上の利点もあります。同じSQL文を繰り返し実行する場合、`prepare`は1回だけ行い、`execute`を値を変えて複数回呼び出すことで効率的に処理できます。

## last_insert_idでID取得

INSERT文を実行した後、自動採番されたIDを取得するには`last_insert_id`メソッドを使います。

```perl
# insert_and_get_id.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $sth = $dbh->prepare(<<'SQL');
INSERT INTO tasks (title, done) VALUES (?, ?)
SQL

$sth->execute('レポートを書く', 0);

# 自動採番されたIDを取得
my $id = $dbh->last_insert_id(undef, undef, 'tasks', 'id');

print "Inserted task with ID: $id\n";
```

このコードのポイントを解説します。

- `$dbh->last_insert_id`は直前のINSERTで採番されたIDを返す
- 引数は順に「カタログ名」「スキーマ名」「テーブル名」「カラム名」
- SQLiteでは最初の2つは`undef`でよい
- テーブル名とカラム名を指定することで、どのIDを取得するか明示する

この`last_insert_id`の戻り値を使って、挿入したレコードを特定したり、ユーザーにフィードバックを返したりできます。

## Taskクラスのsaveメソッド

ここまでの知識を使って、Taskクラスに`save`メソッドを追加しましょう。このメソッドは、タスクをデータベースに保存し、自動採番されたIDを自身の`id`属性に設定します。

```perl
# lib/Task.pm に追加
# Perl 5.40+
# 外部依存: Moo, DBI, DBD::SQLite

sub save {
    my $self = shift;

    my $dbh = DB::get_dbh();
    my $sth = $dbh->prepare(<<'SQL');
INSERT INTO tasks (title, done) VALUES (?, ?)
SQL

    $sth->execute($self->title, $self->done ? 1 : 0);

    my $id = $dbh->last_insert_id(undef, undef, 'tasks', 'id');
    $self->id($id);

    return $self;
}
```

このメソッドのポイントを解説します。

- `DB::get_dbh()`でSingletonのDBハンドルを取得する
- `$self->title`と`$self->done`で自身の属性値を取得する
- `$self->done ? 1 : 0`で真偽値を0/1に変換する
- `$self->id($id)`で採番されたIDを自身に設定する
- `return $self`でメソッドチェーンを可能にする

これにより、以下のようにタスクを作成・保存できるようになります。

```perl
use Task;
use DB;

my $task = Task->new(title => '牛乳を買う');
$task->save();

print "Added: [" . $task->id . "] " . $task->title . "\n";
# 出力: Added: [1] 牛乳を買う
```

## 次回予告

次回は、データベースからタスクを取得するSELECT文（Read操作）を実装します。`fetchrow_hashref`でデータを取得し、Taskオブジェクトの配列として返す方法を学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. [第5回 - ファイル版の限界とデータベースへの移行](/post/perl-todo-cli-05/)
6. **第6回 - タスクをデータベースに追加する**（この記事）
7. 第7回 - タスク一覧を表示する（予定）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
