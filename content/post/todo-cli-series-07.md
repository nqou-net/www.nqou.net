---
title: "コマンドを増やす｜完了機能を追加 - シンプルなTodo CLIアプリ 第7回"
draft: true
tags:
  - perl
  - command-pattern
  - design-patterns
  - todo-app
description: "Command::Completeを追加し、Commandパターンの拡張性を体験します。新機能追加が既存コードにほとんど影響しない設計の威力を実感しましょう。"
---

[@nqounet](https://x.com/nqounet)です。

シリーズ「シンプルなTodo CLIアプリ」の第7回です。

## 前回の振り返り

前回は、Commandパターンを導入してif-elsif分岐を解消しました。

- `Command::Role` でインターフェースを定義
- `Command::Add`, `Command::List` を実装
- 各コマンドが独立したクラスになった

今回は Command::Complete を追加し、Commandパターンの 拡張性 を体験します。

## Command::Complete の実装

### タスク完了コマンド

指定されたIDのタスクを完了状態にするコマンドを実装します。

```perl
package Command::Complete {
    use Moo;

    with 'Command::Role';

    has repository => (is => 'ro', required => 1);
    has task_id    => (is => 'ro', required => 1);

    sub execute {
        my $self = shift;

        my $task = $self->repository->find($self->task_id);

        if (!$task) {
            print "Task " . $self->task_id . " not found.\n";
            return;
        }

        $task->mark_done();
        $self->repository->save($task);

        print "Completed: " . $task->title . "\n";
    }

    sub description {
        return 'Complete a task by ID';
    }
}
```

### 属性の説明

| 属性 | 説明 |
|-----|------|
| `repository` | タスクを取得・保存するRepository |
| `task_id` | 完了するタスクのID |

## 既存コードへの変更

### ハッシュにエントリを追加するだけ

新しいコマンドを追加するには、コマンドマップにエントリを追加するだけです。

```perl
my %command_map = (
    add => sub {
        my $title = shift @ARGV;
        die "Usage: $0 add <task>\n" unless defined $title && $title ne '';
        return Command::Add->new(repository => $repository, title => $title);
    },
    list => sub {
        return Command::List->new(repository => $repository);
    },
    complete => sub {  # 追加！
        my $id = shift @ARGV;
        die "Usage: $0 complete <id>\n" unless defined $id && $id =~ /^\d+$/;
        return Command::Complete->new(repository => $repository, task_id => $id);
    },
);
```

既存の `add` や `list` のコードには一切触れていません。これがCommandパターンの威力です。

### 使用例

```bash
$ perl todo.pl add "牛乳を買う"
Added: 牛乳を買う (ID: 1)

$ perl todo.pl add "メールを返信する"
Added: メールを返信する (ID: 2)

$ perl todo.pl list
1. [ ] 牛乳を買う
2. [ ] メールを返信する

$ perl todo.pl complete 1
Completed: 牛乳を買う

$ perl todo.pl list
1. [x] 牛乳を買う
2. [ ] メールを返信する
```

## 完成したtodo.pl

### 全体コード

Commandパターンを使った完成版のコードです。

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use JSON;

# === Taskクラスの定義 ===
package Task {
    use Moo;

    has id => (
        is      => 'rw',
        default => sub { 0 },
    );

    has title => (
        is       => 'ro',
        required => 1,
    );

    has is_done => (
        is      => 'rw',
        default => sub { 0 },
    );

    sub mark_done {
        my $self = shift;
        $self->is_done(1);
    }
}

# === TaskRepository::Role ===
package TaskRepository::Role {
    use Moo::Role;

    requires 'save';
    requires 'find';
    requires 'all';
    requires 'remove';
}

# === TaskRepository::File ===
package TaskRepository::File {
    use Moo;
    use JSON;

    with 'TaskRepository::Role';

    has filepath => (
        is      => 'ro',
        default => sub { 'tasks.json' },
    );

    sub _load {
        my $self = shift;
        my @tasks;

        return @tasks unless -e $self->filepath;

        open my $fh, '<:encoding(UTF-8)', $self->filepath or die $!;
        my $json = do { local $/; <$fh> };
        close $fh;

        my $data = decode_json($json);

        for my $item (@$data) {
            push @tasks, Task->new(
                id      => $item->{id},
                title   => $item->{title},
                is_done => $item->{is_done} ? 1 : 0,
            );
        }

        return @tasks;
    }

    sub _save_all {
        my ($self, @tasks) = @_;

        my @data = map {
            {
                id      => $_->id,
                title   => $_->title,
                is_done => $_->is_done ? \1 : \0,
            }
        } @tasks;

        open my $fh, '>:encoding(UTF-8)', $self->filepath or die $!;
        print $fh encode_json(\@data);
        close $fh;
    }

    sub save {
        my ($self, $task) = @_;
        my @tasks = $self->_load;

        if ($task->id && $task->id > 0) {
            my $found = 0;
            for my $t (@tasks) {
                if ($t->id == $task->id) {
                    $t->is_done($task->is_done);
                    $found = 1;
                    last;
                }
            }
            push @tasks, $task unless $found;
        }
        else {
            my $max_id = 0;
            for my $t (@tasks) {
                $max_id = $t->id if $t->id > $max_id;
            }
            $task->id($max_id + 1);
            push @tasks, $task;
        }

        $self->_save_all(@tasks);
        return $task;
    }

    sub find {
        my ($self, $id) = @_;
        my @tasks = $self->_load;

        for my $task (@tasks) {
            return $task if $task->id == $id;
        }
        return;
    }

    sub all {
        my $self = shift;
        return $self->_load;
    }

    sub remove {
        my ($self, $id) = @_;
        my @tasks = $self->_load;
        my $original_count = @tasks;

        @tasks = grep { $_->id != $id } @tasks;

        if (@tasks < $original_count) {
            $self->_save_all(@tasks);
            return 1;
        }
        return 0;
    }
}

# === TaskRepository::InMemory ===
package TaskRepository::InMemory {
    use Moo;

    with 'TaskRepository::Role';

    has storage => (
        is      => 'rw',
        default => sub { {} },
    );

    has next_id => (
        is      => 'rw',
        default => sub { 1 },
    );

    sub save {
        my ($self, $task) = @_;

        if (!$task->id || $task->id == 0) {
            $task->id($self->next_id);
            $self->next_id($self->next_id + 1);
        }

        $self->storage->{$task->id} = $task;
        return $task;
    }

    sub find {
        my ($self, $id) = @_;
        return $self->storage->{$id};
    }

    sub all {
        my $self = shift;
        return values %{$self->storage};
    }

    sub remove {
        my ($self, $id) = @_;

        if (exists $self->storage->{$id}) {
            delete $self->storage->{$id};
            return 1;
        }
        return 0;
    }
}

# === Command::Role ===
package Command::Role {
    use Moo::Role;

    requires 'execute';
    requires 'description';
}

# === Command::Add ===
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

# === Command::List ===
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

# === Command::Complete ===
package Command::Complete {
    use Moo;

    with 'Command::Role';

    has repository => (is => 'ro', required => 1);
    has task_id    => (is => 'ro', required => 1);

    sub execute {
        my $self = shift;

        my $task = $self->repository->find($self->task_id);

        if (!$task) {
            print "Task " . $self->task_id . " not found.\n";
            return;
        }

        $task->mark_done();
        $self->repository->save($task);

        print "Completed: " . $task->title . "\n";
    }

    sub description {
        return 'Complete a task by ID';
    }
}

# === メイン処理 ===
package main;

my $repository;
if ($ENV{TODO_TEST_MODE}) {
    $repository = TaskRepository::InMemory->new;
}
else {
    $repository = TaskRepository::File->new(filepath => 'tasks.json');
}

my %command_map = (
    add => sub {
        my $title = shift @ARGV;
        die "Usage: $0 add <task>\n" unless defined $title && $title ne '';
        return Command::Add->new(repository => $repository, title => $title);
    },
    list => sub {
        return Command::List->new(repository => $repository);
    },
    complete => sub {
        my $id = shift @ARGV;
        die "Usage: $0 complete <id>\n" unless defined $id && $id =~ /^\d+$/;
        return Command::Complete->new(repository => $repository, task_id => $id);
    },
);

my $cmd_name = shift @ARGV // 'help';

if (exists $command_map{$cmd_name}) {
    my $command = $command_map{$cmd_name}->();
    $command->execute;
}
else {
    print "Usage: $0 <command> [args]\n";
    print "Commands:\n";
    print "  add <task>      - Add a new task\n";
    print "  list            - List all tasks\n";
    print "  complete <id>   - Complete a task by ID\n";
}
```

## 拡張性を実感する

### 新機能追加のステップ

Commandパターンを使うと、新機能追加は以下の3ステップで完了します。

1. 新しいCommandクラスを実装
2. コマンドマップにエントリを追加
3. ヘルプにコマンドを追加（オプション）

既存のCommandクラスには 一切触れません。これが「オープン・クローズド原則」の実践です。

### 既存コードへの影響

| 追加対象 | 影響範囲 |
|---------|---------|
| `Command::Add` | なし |
| `Command::List` | なし |
| `Command::Complete` | 新規追加のみ |
| コマンドマップ | 1行追加 |

## 発展課題: Command::Delete の実装

### 削除機能を追加してみよう

練習として、タスクを削除する `Command::Delete` を実装してみましょう。

#### ヒント

```perl
package Command::Delete {
    use Moo;

    with 'Command::Role';

    has repository => (is => 'ro', required => 1);
    has task_id    => (is => 'ro', required => 1);

    sub execute {
        my $self = shift;

        # 1. find() でタスクが存在するか確認
        # 2. 存在しなければエラーメッセージを表示
        # 3. remove() でタスクを削除
        # 4. 成功メッセージを表示
    }

    sub description {
        return 'Delete a task by ID';
    }
}
```

#### ポイント

- `find()` でタスクの存在を確認してから `remove()` を呼ぶ
- 削除前にタスクのタイトルを取得しておくと、メッセージに表示できる
- コマンドマップへの追加も忘れずに

### 期待される動作

```bash
$ perl todo.pl list
1. [x] 牛乳を買う
2. [ ] メールを返信する

$ perl todo.pl delete 1
Deleted: 牛乳を買う

$ perl todo.pl list
2. [ ] メールを返信する
```

## Commandパターンの応用

### Undo機能への発展

Commandパターンは「元に戻す」機能と相性が良いです。

```perl
package Command::Role {
    use Moo::Role;

    requires 'execute';
    requires 'description';
    # requires 'undo';  # 将来追加
}
```

各Commandに `undo` メソッドを実装すれば、操作を取り消す仕組みが作れます。

### ログ機能

コマンドの実行履歴を記録することも簡単です。

```perl
# 実行前にログ出力
print "[LOG] Executing: " . ref($command) . "\n";
$command->execute;
```

Commandがオブジェクトなので、どの操作が実行されたかを追跡できます。

## まとめ

今回は、Command::Completeを追加し、Commandパターンの拡張性を体験しました。

- `Command::Complete` を実装
- 既存コードへの影響が最小限
- 新機能追加は「クラス追加 + マップ追加」だけ
- オープン・クローズド原則の実践

Commandパターンの威力を実感できたでしょうか。各操作がオブジェクトとして独立しているため、変更に強く、テストしやすい設計になっています。

次回は、Getopt::Longでコマンドライン引数の解析を整理します。`--verbose` などのオプションにも対応し、より堅牢なCLIに仕上げましょう。

お楽しみに！
