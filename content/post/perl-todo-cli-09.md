---
title: "第9回-タスクを削除する（Delete） - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - dbi
  - crud
description: "Perl DBIでDELETE文を使ってデータベースからレコードを削除。削除確認プロンプトでユーザーに確認を取る安全な削除処理の実装方法を解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第9回です。今回は、不要なタスクを削除するDELETE文について学び、Taskクラスに`delete`メソッドを実装します。

## 前回の振り返り

前回は、タスクを完了状態にするUPDATE文について学び、Taskクラスに`update`メソッドを実装しました。

{{< linkcard "/post/perl-todo-cli-08/" >}}

`execute`の戻り値で更新行数を確認し、ユーザーに適切なフィードバックを返す方法を学びました。今回は、タスクをデータベースから完全に削除する方法を学びます。

## CRUDの「D」- Delete

これまでのシリーズで、CRUDの「C」「R」「U」を実装してきました。

- **C**reate（作成）: データを追加する（第6回）
- **R**ead（読み取り）: データを取得する（第7回）
- **U**pdate（更新）: データを変更する（第8回）
- **D**elete（削除）: データを削除する

今回は「D」、Delete操作を実装します。SQLでは`DELETE`文を使ってデータを削除します。

## DELETE文の基本

タスクを削除するには、`DELETE`文を使用します。

```perl
# delete_task.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $task_id = 1;  # 削除するタスクのID

my $sth = $dbh->prepare(<<'SQL');
DELETE FROM tasks WHERE id = ?
SQL

my $rows = $sth->execute($task_id);

if ($rows > 0) {
    print "Task $task_id deleted.\n";
} else {
    print "Task $task_id not found.\n";
}
```

このコードのポイントを解説します。

- `DELETE FROM tasks`で削除対象のテーブルを指定する
- `WHERE id = ?`でプレースホルダを使い、削除対象のレコードを限定する
- `WHERE`句がないと全レコードが削除されてしまうため、必ず条件を指定する
- `$sth->execute`の戻り値で、削除された行数を確認する
- 存在しないIDを指定した場合、削除行数は`0`になる

`WHERE`句は非常に重要です。条件を忘れると、すべてのタスクが削除されてしまいます。UPDATE文と同様に、必ず条件を指定することを忘れないでください。

## 削除確認プロンプト

削除は取り消しができない操作です。ユーザーが誤って重要なタスクを削除しないよう、削除前に確認を取ることが重要です。

```perl
# delete_with_confirm.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

my $task_id = 1;

# 削除対象のタスクを取得して表示
my $sth = $dbh->prepare('SELECT title FROM tasks WHERE id = ?');
$sth->execute($task_id);
my $row = $sth->fetchrow_hashref;

if (!$row) {
    print "Task $task_id not found.\n";
    exit;
}

print "Delete '$row->{title}'? (y/N): ";
my $answer = <STDIN>;
chomp $answer;

if (lc($answer) eq 'y') {
    my $del_sth = $dbh->prepare('DELETE FROM tasks WHERE id = ?');
    $del_sth->execute($task_id);
    print "Task deleted.\n";
} else {
    print "Cancelled.\n";
}
```

このコードのポイントを解説します。

- 削除前にSELECT文で対象タスクを取得し、タイトルを表示する
- タスクが存在しない場合は、早期に処理を終了する
- `(y/N)`の形式で確認を求める（大文字の`N`がデフォルトであることを示す）
- `lc($answer)`で入力を小文字に変換し、大文字小文字を区別せずに比較する
- `y`以外の入力はすべてキャンセルとして扱う（安全側に倒す設計）

## Taskクラスのdeleteメソッド

ここまでの知識を使って、Taskクラスに`delete`メソッドを追加しましょう。このメソッドは、オブジェクトに対応するレコードをデータベースから削除します。

```perl
# lib/Task.pm に追加
# Perl 5.40+
# 外部依存: Moo, DBI, DBD::SQLite

sub delete {
    my $self = shift;

    my $dbh = DB::get_dbh();
    my $sth = $dbh->prepare(<<'SQL');
DELETE FROM tasks WHERE id = ?
SQL

    my $rows = $sth->execute($self->id);

    return $rows > 0;
}
```

このメソッドのポイントを解説します。

- `WHERE id = ?`で自身のIDを条件に指定し、正しいレコードを削除する
- 戻り値は削除の成否を真偽値で返す（削除できれば真、見つからなければ偽）
- UPDATE文の`update`メソッドと同様のパターンで実装している

これにより、以下のようにタスクを削除できるようになります。

```perl
use Task;
use DB;

# タスクを取得
my $tasks = Task->find_all();
my $task = $tasks->[0];  # 最初のタスク

# 削除を実行
if ($task->delete()) {
    print "Task '" . $task->title . "' deleted!\n";
} else {
    print "Failed to delete task.\n";
}
```

## CRUD操作の完成

これで、CRUD操作がすべて揃いました。

| 操作 | SQL文 | Taskクラスのメソッド |
|------|-------|---------------------|
| Create | INSERT | `save` |
| Read | SELECT | `find_all` |
| Update | UPDATE | `update` |
| Delete | DELETE | `delete` |

Taskクラスを使うことで、SQLを意識せずにタスクのCRUD操作ができるようになりました。これは**ActiveRecord**と呼ばれるパターンの基本形です。

## 次回予告

次回は、コマンドライン引数を処理して、サブコマンド形式のUIを実装します。`Getopt::Long`モジュールを使って、引数を解析する方法と、コマンドごとに処理を切り替える**Strategyパターン**について学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. [第5回 - ファイル版の限界とデータベースへの移行](/post/perl-todo-cli-05/)
6. [第6回 - タスクをデータベースに追加する](/post/perl-todo-cli-06/)
7. [第7回 - タスク一覧を表示する](/post/perl-todo-cli-07/)
8. [第8回 - タスクを完了にする](/post/perl-todo-cli-08/)
9. **第9回 - タスクを削除する**（この記事）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
