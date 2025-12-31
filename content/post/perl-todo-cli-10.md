---
title: "第10回-コマンドライン引数でサクサク操作 - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - cli
  - getopt-long
  - strategy
description: "Perl Getopt::Longでサブコマンド形式のCLIを実装。StrategyパターンでコマンドをMooクラスに整理し、拡張性の高いTODOアプリを完成させます。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第10回、最終回です。今回は、メニュー形式から脱却し、`Getopt::Long`を使ってサブコマンド形式のCLIを実装します。さらに、Strategyパターンを適用して、拡張しやすい設計に進化させます。

全10回の連載を通じて、ファイル入出力からデータベース操作、そしてCLI設計まで、一つのアプリケーションを段階的に構築してきました。最終回では、これまで作成したTaskクラスやDB.pmを活用しながら、コマンドラインからサクサク操作できるツールに仕上げます。

## 前回の振り返り

前回は、タスクを削除するDELETE文について学び、Taskクラスに`delete`メソッドを実装しました。

{{< linkcard "/post/perl-todo-cli-09/" >}}

これでCRUD操作（Create, Read, Update, Delete）がすべて揃いました。今回は、これらの操作をコマンドライン引数で呼び出せるようにします。

## メニュー形式の限界

これまで実装してきたメニュー形式のUIは、対話的で初心者には分かりやすいものでした。

```text
=== TODO アプリ ===
1. タスクを追加
2. タスク一覧を表示
3. タスクを完了にする
4. タスクを削除
5. 終了
選択してください:
```

しかし、この形式にはいくつかの問題があります。

- タスクを1つ追加するだけでも、プログラムを起動 → メニューを見る → 1を入力 → タスク名を入力 → 終了、と手順が多い
- シェルスクリプトや他のプログラムから呼び出しにくい
- 複数の操作を連続で実行しにくい

一方、多くのCLIツール（`git`、`npm`、`docker`など）は、サブコマンド形式を採用しています。

```bash
$ todo add "牛乳を買う"
$ todo list
$ todo done 1
$ todo rm 1
```

この形式なら、1行のコマンドで操作が完結し、シェルスクリプトへの組み込みも容易です。

## Getopt::LongとStrategyパターン

サブコマンド形式のCLIを実装するために、2つの技術を組み合わせます。

`Getopt::Long`は、Perlの標準モジュールで、コマンドライン引数を柔軟に解析できます。詳細については以下の記事を参照してください。

{{< linkcard "/2025/12/21/000000/" >}}

**Strategyパターン**は、アルゴリズム（この場合はサブコマンドの処理）をクラスとしてカプセル化し、実行時に切り替えられるようにするデザインパターンです。

今回は、以下の設計でサブコマンドを実装します。

- 共通のインターフェース（`execute`メソッド）を持つCommandロールを定義する
- 各サブコマンド（add, list, done, rm）をそれぞれMooクラスとして実装する
- メインスクリプトで、サブコマンドに応じたクラスを選択し、実行する

この設計により、新しいサブコマンドを追加する際は、新しいクラスを作成してハッシュに登録するだけで済みます。

```perl
# lib/TodoApp/Command.pm - Commandロール
# Perl 5.40+
# 外部依存: Moo::Role

package TodoApp::Command;
use Moo::Role;

# 全てのコマンドは execute メソッドを実装する必要がある
requires 'execute';

1;

# lib/TodoApp/Command/Add.pm - addコマンド
# Perl 5.40+
# 外部依存: Moo

package TodoApp::Command::Add;
use Moo;
with 'TodoApp::Command';

use Task;
use DB;

sub execute {
    my ($self, @args) = @_;

    my $title = $args[0] // die "Usage: todo add <title>\n";

    my $task = Task->new(title => $title);
    $task->save();

    print "Added: [" . $task->id . "] " . $task->title . "\n";
}

1;

# lib/TodoApp/Command/List.pm - listコマンド
# Perl 5.40+
# 外部依存: Moo, Getopt::Long

package TodoApp::Command::List;
use Moo;
with 'TodoApp::Command';

use Getopt::Long qw(GetOptionsFromArray);
use Task;
use DB;

sub execute {
    my ($self, @args) = @_;

    my $pending_only = 0;
    GetOptionsFromArray(\@args, 'pending' => \$pending_only);

    my $tasks = Task->find_all(pending_only => $pending_only);

    for my $task (@$tasks) {
        my $status = $task->done ? 'x' : ' ';
        printf "[%s] %d. %s\n", $status, $task->id, $task->title;
    }
}

1;

# lib/TodoApp/Command/Done.pm - doneコマンド
# Perl 5.40+
# 外部依存: Moo

package TodoApp::Command::Done;
use Moo;
with 'TodoApp::Command';

use Task;
use DB;

sub execute {
    my ($self, @args) = @_;

    my $task_id = $args[0] // die "Usage: todo done <id>\n";

    my $tasks = Task->find_all();
    my ($task) = grep { $_->id == $task_id } @$tasks;

    if (!$task) {
        die "Task $task_id not found.\n";
    }

    $task->done(1);
    $task->update();

    print "Done: [" . $task->id . "] " . $task->title . "\n";
}

1;

# lib/TodoApp/Command/Delete.pm - rmコマンド
# Perl 5.40+
# 外部依存: Moo

package TodoApp::Command::Delete;
use Moo;
with 'TodoApp::Command';

use Task;
use DB;

sub execute {
    my ($self, @args) = @_;

    my $task_id = $args[0] // die "Usage: todo rm <id>\n";

    my $tasks = Task->find_all();
    my ($task) = grep { $_->id == $task_id } @$tasks;

    if (!$task) {
        die "Task $task_id not found.\n";
    }

    $task->delete();

    print "Deleted: [" . $task->id . "] " . $task->title . "\n";
}

1;
```

このコードのポイントを解説します。

- `Moo::Role`を使って、共通インターフェース（`execute`メソッド）を`requires`で強制する
- 各コマンドクラスは`with 'TodoApp::Command'`でロールを適用し、`execute`メソッドを実装する
- Listコマンドでは`GetOptionsFromArray`を使い、`--pending`オプションを解析する
- 引数が不足している場合は、使い方を表示して終了する

## 完成したtodo.plの全体像

最後に、メインスクリプト`todo.pl`の完成形を見てみましょう。

```perl
#!/usr/bin/env perl
# todo.pl - シンプルなTodo CLIアプリ
# Perl 5.40+
# 外部依存: Moo, DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';

use TodoApp::Command::Add;
use TodoApp::Command::List;
use TodoApp::Command::Done;
use TodoApp::Command::Delete;

# サブコマンドとクラスのマッピング
my %commands = (
    add  => TodoApp::Command::Add->new,
    list => TodoApp::Command::List->new,
    done => TodoApp::Command::Done->new,
    rm   => TodoApp::Command::Delete->new,
);

# ヘルプメッセージ
sub show_help {
    print <<'HELP';
Usage: todo <command> [options] [arguments]

Commands:
    add <title>     Add a new task
    list [--pending] List tasks (--pending for incomplete only)
    done <id>       Mark task as done
    rm <id>         Remove task

Examples:
    todo add "牛乳を買う"
    todo list
    todo list --pending
    todo done 1
    todo rm 1
HELP
    exit 0;
}

# メイン処理
my $subcommand = shift @ARGV // 'help';

if ($subcommand eq 'help' || $subcommand eq '--help' || $subcommand eq '-h') {
    show_help();
}

my $cmd = $commands{$subcommand};
if (!$cmd) {
    die "Unknown command: $subcommand\nRun 'todo help' for usage.\n";
}

$cmd->execute(@ARGV);
```

このスクリプトのポイントを解説します。

- `%commands`ハッシュで、サブコマンド名とコマンドオブジェクトを対応付ける
- `shift @ARGV`で最初の引数（サブコマンド）を取得する
- 残りの`@ARGV`はコマンドクラスの`execute`メソッドに渡す
- 未知のサブコマンドはエラーメッセージを表示して終了する
- `help`、`--help`、`-h`でヘルプを表示する

これで、以下のようにコマンドラインから操作できるようになりました。

```text
$ perl todo.pl add "牛乳を買う"
Added: [1] 牛乳を買う

$ perl todo.pl add "レポートを書く"
Added: [2] レポートを書く

$ perl todo.pl list
[ ] 1. 牛乳を買う
[ ] 2. レポートを書く

$ perl todo.pl done 1
Done: [1] 牛乳を買う

$ perl todo.pl list
[x] 1. 牛乳を買う
[ ] 2. レポートを書く

$ perl todo.pl list --pending
[ ] 2. レポートを書く

$ perl todo.pl rm 1
Deleted: [1] 牛乳を買う
```

## シリーズのまとめ

全10回の連載を通じて、シンプルなTODOアプリを段階的に構築してきました。学んだ概念を振り返ります。

| 回 | 概念 | 内容 |
|----|------|------|
| 第1回 | アプリ設計 | 完成イメージ、TodoAppクラスの骨格、Commandパターンへの伏線 |
| 第2回 | STDIN | ユーザー入力の受け取り、chomp、対話型メニューUI |
| 第3回 | ファイル書き込み | `open`の書き込みモード、Taskクラスの設計 |
| 第4回 | ファイル読み込み | `open`の読み込みモード、行ごとの処理 |
| 第5回 | DBI接続 | SQLiteへの接続、Singletonパターン、CREATE TABLE |
| 第6回 | INSERT文 | prepareとexecute、last_insert_id、saveメソッド |
| 第7回 | SELECT文 | 全件取得、WHERE句によるフィルタ、find_allメソッド |
| 第8回 | UPDATE文 | done属性の更新、updateメソッド |
| 第9回 | DELETE文 | レコードの削除、削除確認プロンプト、deleteメソッド |
| 第10回 | Getopt::Long + Strategy | サブコマンド形式CLI、Commandロール、拡張性の高い設計 |

ファイル入出力からデータベース操作へ、メニュー形式からサブコマンド形式へと、アプリケーションが成長する過程を体験しました。

## 今後の発展

このTODOアプリは、さらに機能を追加して発展させることができます。

- **優先度の追加**: `priority`カラムを追加し、タスクの重要度を管理する
- **期限の管理**: `due_date`カラムを追加し、期限切れタスクを警告する
- **カテゴリ・タグ**: タスクをカテゴリやタグで分類する
- **エクスポート/インポート**: CSVやJSON形式でデータをバックアップ・復元する
- **設定ファイル**: データベースのパスや表示形式を設定ファイルで管理する
- **カラー表示**: `Term::ANSIColor`を使って、完了タスクを緑色で表示する

これらの機能追加は、今回実装したStrategyパターンの設計により、既存のコードを大きく変更せずに実現できます。新しいサブコマンドは、新しいコマンドクラスを作成して`%commands`に追加するだけです。

## おわりに

「シンプルなTodo CLIアプリ」シリーズ、全10回をお読みいただきありがとうございました。

この連載では、「Mooで覚えるオブジェクト指向プログラミング」シリーズで学んだクラス設計のスキルを活かして、実用的なCLIアプリケーションを構築しました。ファイル入出力の基礎から、データベース操作、そしてコマンドライン処理まで、一つのアプリケーションを通じて学ぶことで、各技術がどのように組み合わさるかを体験できたと思います。

ぜひ、このTODOアプリをベースに、自分だけの機能を追加してみてください。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. [第5回 - ファイル版の限界とデータベースへの移行](/post/perl-todo-cli-05/)
6. [第6回 - タスクをデータベースに追加する](/post/perl-todo-cli-06/)
7. [第7回 - タスク一覧を表示する](/post/perl-todo-cli-07/)
8. [第8回 - タスクを完了にする](/post/perl-todo-cli-08/)
9. [第9回 - タスクを削除する](/post/perl-todo-cli-09/)
10. **第10回 - コマンドライン引数でサクサク操作**（この記事）
