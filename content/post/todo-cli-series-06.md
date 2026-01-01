---
title: "if文地獄から脱出｜Commandパターン導入 - シンプルなTodo CLIアプリ 第6回"
draft: true
tags:
  - perl
  - command-pattern
  - design-patterns
  - todo-app
description: "肥大化したif-elsif分岐をCommandパターンで解消します。各操作をCommand::Add、Command::Listなどのオブジェクトに分離し、拡張性の高い設計を学びましょう。"
---

[@nqounet](https://x.com/nqounet)です。

シリーズ「シンプルなTodo CLIアプリ」の第6回です。

## 前回の振り返り

前回は、InMemoryRepositoryを実装してテスト容易性を高めました。

- `TaskRepository::InMemory` でメモリ上にタスクを保存
- ファイルI/Oなしでテストが可能に
- 同じインターフェースで実装を切り替えられる

Repositoryパターンの真価を体感しました。今回は、メイン処理の **if-elsif分岐** を整理し、**Commandパターン** を導入します。

## if-elsif分岐の問題点

### 現状のコードを見てみましょう

現在のメイン処理は以下のようになっています。

```perl
my $command = shift @ARGV // 'help';

if ($command eq 'add') {
    my $title = shift @ARGV;
    die "Usage: $0 add <task>\n" unless defined $title && $title ne '';

    my $task = Task->new(title => $title);
    $repository->save($task);

    print "Added: $title (ID: " . $task->id . ")\n";
}
elsif ($command eq 'list') {
    my @tasks = $repository->all;

    if (@tasks == 0) {
        print "No tasks.\n";
        exit;
    }

    for my $task (sort { $a->id <=> $b->id } @tasks) {
        my $status = $task->is_done ? '[x]' : '[ ]';
        printf "%d. %s %s\n", $task->id, $status, $task->title;
    }
}
elsif ($command eq 'complete') {
    my $id = shift @ARGV;
    die "Usage: $0 complete <id>\n" unless defined $id && $id =~ /^\d+$/;

    my $task = $repository->find($id);
    die "Task $id not found.\n" unless $task;

    $task->mark_done();
    $repository->save($task);

    print "Completed: " . $task->title . "\n";
}
else {
    print "Usage: $0 <command> [args]\n";
    print "Commands:\n";
    print "  add <task>      - Add a new task\n";
    print "  list            - List all tasks\n";
    print "  complete <id>   - Complete a task by ID\n";
}
```

3つのコマンドだけでこの長さです。

### コマンドが増えるとどうなるか

新しいコマンド（`delete`, `edit`, `search` など）を追加するたびに、if-elsif分岐が長くなります。

```perl
if ($command eq 'add') {
    # ...
}
elsif ($command eq 'list') {
    # ...
}
elsif ($command eq 'complete') {
    # ...
}
elsif ($command eq 'delete') {     # 追加
    # ...
}
elsif ($command eq 'edit') {       # 追加
    # ...
}
elsif ($command eq 'search') {     # 追加
    # ...
}
# どんどん長くなる...
```

問題点:

- 見通しが悪くなる
- 修正箇所が分かりにくい
- 1つのファイルが巨大になる
- 各コマンドの単体テストが困難

## Commandパターンとは

### 操作をオブジェクトにする

Commandパターンは、**各操作をオブジェクトとしてカプセル化する** デザインパターンです。

```
Before:
┌─────────────┐
│ if-elsif    │ → 直接処理を実行
│ 分岐の嵐    │
└─────────────┘

After:
┌─────────────┐     ┌──────────────┐
│ コマンド名  │ ──→ │ Commandオブ  │ ──→ 処理を実行
│ を判定      │     │ ジェクト     │
└─────────────┘     └──────────────┘
```

各コマンドは独立したクラスになります。

- `Command::Add` - タスク追加
- `Command::List` - 一覧表示
- `Command::Complete` - タスク完了

### メリット

| メリット | 説明 |
|---------|------|
| **分離** | 各コマンドが独立したクラスになる |
| **拡張性** | 新しいコマンドはクラスを追加するだけ |
| **テスト容易** | コマンドごとに単体テストが書ける |
| **可読性** | 責務が明確で理解しやすい |

## Command::Role の定義

### インターフェースを決める

まず、すべてのCommandクラスが持つべきメソッドをMoo::Roleで定義します。

```perl
package Command::Role {
    use Moo::Role;

    requires 'execute';      # コマンドを実行する
    requires 'description';  # コマンドの説明を返す
}
```

`requires` で宣言されたメソッドは、このRoleを適用するクラスが必ず実装しなければなりません。

{{< linkcard "/2025/12/30/163818/" >}}

### なぜdescriptionメソッドが必要か

`description` メソッドを用意しておくと、ヘルプ表示を自動生成できます。

```perl
# 各コマンドにdescriptionがあれば
for my $name (sort keys %commands) {
    my $cmd = $commands{$name};
    printf "  %-12s - %s\n", $name, $cmd->description;
}
```

後で動的にヘルプを生成する仕組みに発展できます。

## Command::Add の実装

### タスク追加コマンド

「タスクを追加する」操作をクラスにまとめます。

```perl
package Command::Add {
    use Moo;

    with 'Command::Role';

    has repository => (is => 'ro', required => 1);
    has title      => (is => 'ro', required => 1);

    sub execute {
        my $self = shift;

        my $task = Task->new(title => $self->title);
        $self->repository->save($task);

        print "Added: " . $self->title . " (ID: " . $task->id . ")\n";
    }

    sub description {
        return 'Add a new task';
    }
}
```

### 属性の説明

| 属性 | 説明 |
|-----|------|
| `repository` | タスクを保存するRepository（DI） |
| `title` | 追加するタスクのタイトル |

`repository` を外部から注入することで、FileでもInMemoryでも使えます。これが依存性注入（DI）の力です。

### 使い方

```perl
my $cmd = Command::Add->new(
    repository => $repository,
    title      => '牛乳を買う',
);
$cmd->execute;  # Added: 牛乳を買う (ID: 1)
```

if-elsif内の処理が、オブジェクトの `execute` メソッド呼び出しに変わりました。

## Command::List の実装

### 一覧表示コマンド

```perl
package Command::List {
    use Moo;

    with 'Command::Role';

    has repository => (is => 'ro', required => 1);

    sub execute {
        my $self = shift;

        my @tasks = $self->repository->all;

        if (@tasks == 0) {
            print "No tasks.\n";
            return;
        }

        for my $task (sort { $a->id <=> $b->id } @tasks) {
            my $status = $task->is_done ? '[x]' : '[ ]';
            printf "%d. %s %s\n", $task->id, $status, $task->title;
        }
    }

    sub description {
        return 'List all tasks';
    }
}
```

### 使い方

```perl
my $cmd = Command::List->new(repository => $repository);
$cmd->execute;
# 1. [ ] 牛乳を買う
# 2. [ ] メールを返信する
```

引数を必要としないコマンドはシンプルです。

## メイン処理の書き換え

### Commandオブジェクトを生成して実行

if-elsif分岐を、Commandオブジェクトの生成と実行に置き換えます。

```perl
my $cmd_name = shift @ARGV // 'help';

my $command;

if ($cmd_name eq 'add') {
    my $title = shift @ARGV;
    die "Usage: $0 add <task>\n" unless defined $title && $title ne '';

    $command = Command::Add->new(
        repository => $repository,
        title      => $title,
    );
}
elsif ($cmd_name eq 'list') {
    $command = Command::List->new(repository => $repository);
}
else {
    print "Usage: $0 <command> [args]\n";
    print "Commands:\n";
    print "  add <task>      - Add a new task\n";
    print "  list            - List all tasks\n";
    exit;
}

$command->execute;
```

### まだif-elsif分岐がある？

確かに、コマンド名の判定にはまだif-elsifが残っています。しかし、重要な違いがあります。

**Before**:

- if-elsif内に「処理の全て」が書かれていた
- 分岐が長大で見通しが悪い

**After**:

- if-elsifは「どのCommandオブジェクトを作るか」だけを決める
- 実際の処理はCommandクラス内にカプセル化
- 各Commandクラスは独立してテスト可能

「コマンドの生成」と「コマンドの実行」が分離されたのです。

## ハッシュでディスパッチを簡潔に

### コマンド名とクラスのマッピング

if-elsif分岐をさらに減らすには、ハッシュを使ってコマンド名とクラスをマッピングします。

```perl
my %command_map = (
    add  => sub {
        my $title = shift @ARGV;
        die "Usage: $0 add <task>\n" unless defined $title && $title ne '';
        return Command::Add->new(repository => $repository, title => $title);
    },
    list => sub {
        return Command::List->new(repository => $repository);
    },
);

my $cmd_name = shift @ARGV // 'help';

if (exists $command_map{$cmd_name}) {
    my $command = $command_map{$cmd_name}->();
    $command->execute;
}
else {
    print "Unknown command: $cmd_name\n";
    # ヘルプ表示...
}
```

この手法は「ディスパッチテーブル」と呼ばれます。新しいコマンドを追加するには、ハッシュにエントリを追加するだけです。

## Commandパターンの効果

### 比較：Before vs After

| 観点 | Before | After |
|------|--------|-------|
| 処理の場所 | if-elsif内に直書き | Commandクラス内 |
| 新コマンド追加 | if-elsifに分岐追加 | クラスを追加 |
| 単体テスト | 困難 | Commandごとに可能 |
| コードの見通し | 悪い | 良い |

### 拡張性の向上

新しいコマンド `Command::Complete` を追加する場合：

1. `Command::Complete` クラスを実装
2. ハッシュにエントリを追加

既存のコードへの影響は最小限です。**オープン・クローズド原則**（拡張に対して開いている、変更に対して閉じている）を実現しています。

## まとめ

今回は、Commandパターンを導入してif-elsif分岐を解消しました。

- `Command::Role` でインターフェースを定義
- `Command::Add`, `Command::List` を実装
- 各コマンドが独立したクラスになった
- 拡張性とテスト容易性が向上

Repositoryパターンに続き、2つ目のデザインパターンを学びました。「操作をオブジェクトにする」という発想は、多くの場面で応用できます。

次回は、`Command::Complete` を追加し、新機能追加の容易さを体験します。Commandパターンの真価を実感しましょう！

お楽しみに！
