---
title: "第8回-タスクを完了にする（Update） - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - dbi
  - crud
description: "Perl DBIでUPDATE文を使ってデータベースのレコードを更新。プレースホルダでIDを指定し、タスクの完了フラグを安全に更新する方法を解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第8回です。今回は、タスクを完了状態にするUPDATE文について学び、Taskクラスに`update`メソッドを実装します。

## 前回の振り返り

前回は、データベースからタスクを取得するSELECT文について学び、Taskクラスに`find_all`メソッドを実装しました。

{{< linkcard "/post/perl-todo-cli-07/" >}}

`fetchrow_hashref`で1行ずつデータを取得し、Taskオブジェクトの配列として返す方法を学びました。今回は、取得したタスクの状態を更新する方法を学びます。

## CRUDの「U」- Update

これまでのシリーズで、CRUDの「C」（Create）と「R」（Read）を実装しました。

- **C**reate（作成）: データを追加する（第6回）
- **R**ead（読み取り）: データを取得する（第7回）
- **U**pdate（更新）: データを変更する
- **D**elete（削除）: データを削除する

今回は「U」、Update操作を実装します。SQLでは`UPDATE`文を使ってデータを変更します。

## UPDATE文の基本

タスクを完了状態にするには、`done`カラムの値を`1`に更新します。

```perl
# update_task.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $task_id = 1;  # 完了にするタスクのID

my $sth = $dbh->prepare(<<'SQL');
UPDATE tasks SET done = 1 WHERE id = ?
SQL

$sth->execute($task_id);

print "Task $task_id marked as done.\n";
```

このコードのポイントを解説します。

- `UPDATE tasks`で更新対象のテーブルを指定する
- `SET done = 1`で`done`カラムを`1`（完了）に変更する
- `WHERE id = ?`でプレースホルダを使い、更新対象のレコードを限定する
- `WHERE`句がないと全レコードが更新されてしまうため、必ず条件を指定する
- プレースホルダを使うことで、SQLインジェクションを防ぐことができる

`WHERE`句は非常に重要です。条件を忘れると、すべてのタスクが完了状態になってしまいます。

## 更新結果の確認とフィードバック

UPDATE文を実行した後、実際に更新が行われたかを確認することが重要です。`execute`メソッドの戻り値で、更新された行数を取得できます。

```perl
# update_with_feedback.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $task_id = 1;

my $sth = $dbh->prepare(<<'SQL');
UPDATE tasks SET done = 1 WHERE id = ?
SQL

my $rows = $sth->execute($task_id);

if ($rows > 0) {
    print "Task $task_id completed successfully.\n";
} else {
    print "Task $task_id not found.\n";
}
```

このコードのポイントを解説します。

- `$sth->execute`の戻り値は、更新された行数を返す
- 存在しないIDを指定した場合、更新行数は`0`になる
- 戻り値を確認することで、ユーザーに適切なフィードバックを返すことができる
- この確認により、「タスクが見つからない」というエラーケースにも対応できる

## Taskクラスのupdateメソッド

ここまでの知識を使って、Taskクラスに`update`メソッドを追加しましょう。このメソッドは、オブジェクトの現在の状態をデータベースに反映します。

```perl
# lib/Task.pm に追加
# Perl 5.40+
# 外部依存: Moo, DBI, DBD::SQLite

sub update {
    my $self = shift;

    my $dbh = DB::get_dbh();
    my $sth = $dbh->prepare(<<'SQL');
UPDATE tasks SET title = ?, done = ? WHERE id = ?
SQL

    my $rows = $sth->execute(
        $self->title,
        $self->done ? 1 : 0,
        $self->id
    );

    return $rows > 0;
}
```

このメソッドのポイントを解説します。

- `title`と`done`の両方を更新対象にすることで、汎用的なメソッドになる
- `$self->done ? 1 : 0`で真偽値を0/1に変換する
- `WHERE id = ?`で自身のIDを条件に指定し、正しいレコードを更新する
- 戻り値は更新の成否を真偽値で返す（更新できれば真、見つからなければ偽）

これにより、以下のようにタスクを完了にできるようになります。

```perl
use Task;
use DB;

# タスクを取得
my $tasks = Task->find_all();
my $task = $tasks->[0];  # 最初のタスク

# 完了に変更
$task->done(1);

# データベースに反映
if ($task->update()) {
    print "Task '" . $task->title . "' completed!\n";
} else {
    print "Failed to update task.\n";
}
```

## 次回予告

次回は、タスクを削除するDELETE文（Delete操作）を実装します。不要になったタスクをデータベースから削除する方法を学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. [第5回 - ファイル版の限界とデータベースへの移行](/post/perl-todo-cli-05/)
6. [第6回 - タスクをデータベースに追加する](/post/perl-todo-cli-06/)
7. [第7回 - タスク一覧を表示する](/post/perl-todo-cli-07/)
8. **第8回 - タスクを完了にする**（この記事）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
