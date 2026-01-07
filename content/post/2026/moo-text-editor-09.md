---
date: 2026-01-07T22:16:24+09:00
description: これまで作成したEditor、コマンドクラス、History、MacroCommandを統合し、対話的に操作できるCLIベースの簡易テキストエディタを完成させます。
draft: true
image: /favicon.png
iso8601: 2026-01-07T22:16:24+09:00
tags:
  - perl
  - moo
  - text-editor
  - cli
title: '第9回-完成！簡易エディタ - 統合と仕上げ - Mooで作る簡易テキストエディタ'
---

[@nqounet](https://x.com/nqounet)です。

シリーズ「Mooで作る簡易テキストエディタ」の第9回です。

## 前回の振り返り

前回は、複数の操作を1つにまとめる`MacroCommand`クラスを実装しました。

{{< linkcard "/2026/moo-text-editor-08/" >}}

`MacroCommand`を使えば、複数の操作を1回のUndo/Redoでまとめて処理できます。

```perl
my $macro = MacroCommand->new;
$macro->add_command($cmd1);
$macro->add_command($cmd2);
$macro->add_command($cmd3);

$history->execute_command($macro);  # 3つの操作を一括実行
$history->undo;                     # 3つの操作を一括Undo
```

今回は、これまで作成した全機能を統合し、**対話的に操作できる簡易エディタ**を完成させます。

## 完成イメージ

最終的に、以下のような対話型CLIエディタを作ります。

```
=== 簡易テキストエディタ ===
コマンド: i(挿入), d(削除), u(undo), r(redo), p(表示), q(終了)

> p
テキスト: ''

> i
挿入位置: 0
挿入文字列: Hello
テキスト: 'Hello'

> i
挿入位置: 5
挿入文字列:  World
テキスト: 'Hello World'

> u
Undo実行
テキスト: 'Hello'

> r
Redo実行
テキスト: 'Hello World'

> q
終了します。
```

## 対話ループを作成する

まず、ユーザーからの入力を受け付ける対話ループを作成します。

```perl
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;

sub main {
    say "=== 簡易テキストエディタ ===";
    say "コマンド: i(挿入), d(削除), u(undo), r(redo), p(表示), q(終了)";
    say "";

    my $editor  = Editor->new;
    my $history = History->new;

    while (1) {
        print "> ";
        my $input = <STDIN>;
        last unless defined $input;  # Ctrl+Dで終了

        chomp $input;
        my $cmd = lc($input);

        if ($cmd eq 'q') {
            say "終了します。";
            last;
        }
        elsif ($cmd eq 'p') {
            show_text($editor);
        }
        elsif ($cmd eq 'i') {
            do_insert($editor, $history);
        }
        elsif ($cmd eq 'd') {
            do_delete($editor, $history);
        }
        elsif ($cmd eq 'u') {
            do_undo($editor, $history);
        }
        elsif ($cmd eq 'r') {
            do_redo($editor, $history);
        }
        else {
            say "不明なコマンド: '$input'";
        }
    }
}

sub show_text ($editor) {
    say "テキスト: '" . $editor->text . "'";
}
```

## 各コマンドハンドラを実装する

次に、各コマンドに対応するハンドラ関数を実装します。

### 挿入コマンド (i)

```perl
sub do_insert ($editor, $history) {
    print "挿入位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    my $position = int($pos_input);
    my $max_pos  = length($editor->text);

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "挿入文字列: ";
    my $string = <STDIN>;
    return unless defined $string;
    chomp $string;

    if ($string eq '') {
        say "エラー: 挿入文字列が空です";
        return;
    }

    my $cmd = InsertCommand->new(
        editor   => $editor,
        position => $position,
        string   => $string,
    );
    $history->execute_command($cmd);
    show_text($editor);
}
```

挿入位置を検証し、範囲外ならエラーメッセージを表示します。

### 削除コマンド (d)

```perl
sub do_delete ($editor, $history) {
    if ($editor->text eq '') {
        say "エラー: テキストが空です";
        return;
    }

    print "削除開始位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    my $position = int($pos_input);
    my $max_pos  = length($editor->text) - 1;

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "削除文字数: ";
    my $len_input = <STDIN>;
    return unless defined $len_input;
    chomp $len_input;

    my $length     = int($len_input);
    my $max_length = length($editor->text) - $position;

    if ($length < 1 || $length > $max_length) {
        say "エラー: 削除文字数は1〜$max_lengthの範囲で指定してください";
        return;
    }

    my $cmd = DeleteCommand->new(
        editor   => $editor,
        position => $position,
        length   => $length,
    );
    $history->execute_command($cmd);
    show_text($editor);
}
```

削除位置と削除文字数を検証し、範囲外ならエラーメッセージを表示します。

### Undoコマンド (u)

```perl
sub do_undo ($editor, $history) {
    if ($history->undo_stack->@* == 0) {
        say "Undoする操作がありません";
        return;
    }

    $history->undo;
    say "Undo実行";
    show_text($editor);
}
```

Undoスタックが空の場合は、メッセージを表示して何もしません。

### Redoコマンド (r)

```perl
sub do_redo ($editor, $history) {
    if ($history->redo_stack->@* == 0) {
        say "Redoする操作がありません";
        return;
    }

    $history->redo;
    say "Redo実行";
    show_text($editor);
}
```

Redoスタックが空の場合は、メッセージを表示して何もしません。

## 完成したエディタスクリプト

では、すべてを統合した完成版のエディタスクリプトを見てみましょう。

```perl
#!/usr/bin/env perl
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;

package Editor {
    use Moo;

    has text => (
        is      => 'rw',
        default => '',
    );
};

package Command::Role {
    use Moo::Role;

    requires 'execute';
    requires 'undo';
};

package InsertCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has string => (
        is       => 'ro',
        required => 1,
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $string   = $self->string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position) 
                     . $string 
                     . substr($current, $position);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = length($self->string);

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position) 
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }
};

package DeleteCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has length => (
        is       => 'ro',
        required => 1,
    );

    has _deleted_string => (
        is      => 'rw',
        default => '',
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = $self->length;

        my $current = $editor->text;
        my $deleted = substr($current, $position, $length);
        $self->_deleted_string($deleted);

        my $new_text = substr($current, 0, $position) 
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $deleted  = $self->_deleted_string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position) 
                     . $deleted 
                     . substr($current, $position);
        $editor->text($new_text);
    }
};

package MacroCommand {
    use Moo;
    with 'Command::Role';

    has commands => (
        is      => 'ro',
        default => sub { [] },
    );

    sub add_command ($self, $command) {
        push $self->commands->@*, $command;
    }

    sub execute ($self) {
        for my $cmd ($self->commands->@*) {
            $cmd->execute;
        }
    }

    sub undo ($self) {
        for my $cmd (reverse $self->commands->@*) {
            $cmd->undo;
        }
    }
};

package History {
    use Moo;

    has undo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    has redo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    sub execute_command ($self, $command) {
        $command->execute;
        push $self->undo_stack->@*, $command;
        $self->redo_stack->@* = ();
    }

    sub undo ($self) {
        return unless $self->undo_stack->@*;

        my $command = pop $self->undo_stack->@*;
        $command->undo;
        push $self->redo_stack->@*, $command;
    }

    sub redo ($self) {
        return unless $self->redo_stack->@*;

        my $command = pop $self->redo_stack->@*;
        $command->execute;
        push $self->undo_stack->@*, $command;
    }
};

# ヘルパー関数
sub show_text ($editor) {
    say "テキスト: '" . $editor->text . "'";
}

sub do_insert ($editor, $history) {
    print "挿入位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    my $position = int($pos_input);
    my $max_pos  = length($editor->text);

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "挿入文字列: ";
    my $string = <STDIN>;
    return unless defined $string;
    chomp $string;

    if ($string eq '') {
        say "エラー: 挿入文字列が空です";
        return;
    }

    my $cmd = InsertCommand->new(
        editor   => $editor,
        position => $position,
        string   => $string,
    );
    $history->execute_command($cmd);
    show_text($editor);
}

sub do_delete ($editor, $history) {
    if ($editor->text eq '') {
        say "エラー: テキストが空です";
        return;
    }

    print "削除開始位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    my $position = int($pos_input);
    my $max_pos  = length($editor->text) - 1;

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "削除文字数: ";
    my $len_input = <STDIN>;
    return unless defined $len_input;
    chomp $len_input;

    my $length     = int($len_input);
    my $max_length = length($editor->text) - $position;

    if ($length < 1 || $length > $max_length) {
        say "エラー: 削除文字数は1〜$max_lengthの範囲で指定してください";
        return;
    }

    my $cmd = DeleteCommand->new(
        editor   => $editor,
        position => $position,
        length   => $length,
    );
    $history->execute_command($cmd);
    show_text($editor);
}

sub do_undo ($editor, $history) {
    if ($history->undo_stack->@* == 0) {
        say "Undoする操作がありません";
        return;
    }

    $history->undo;
    say "Undo実行";
    show_text($editor);
}

sub do_redo ($editor, $history) {
    if ($history->redo_stack->@* == 0) {
        say "Redoする操作がありません";
        return;
    }

    $history->redo;
    say "Redo実行";
    show_text($editor);
}

# メイン処理
sub main {
    say "=== 簡易テキストエディタ ===";
    say "コマンド: i(挿入), d(削除), u(undo), r(redo), p(表示), q(終了)";
    say "";

    my $editor  = Editor->new;
    my $history = History->new;

    while (1) {
        print "> ";
        my $input = <STDIN>;
        last unless defined $input;

        chomp $input;
        my $cmd = lc($input);

        if ($cmd eq 'q') {
            say "終了します。";
            last;
        }
        elsif ($cmd eq 'p') {
            show_text($editor);
        }
        elsif ($cmd eq 'i') {
            do_insert($editor, $history);
        }
        elsif ($cmd eq 'd') {
            do_delete($editor, $history);
        }
        elsif ($cmd eq 'u') {
            do_undo($editor, $history);
        }
        elsif ($cmd eq 'r') {
            do_redo($editor, $history);
        }
        else {
            say "不明なコマンド: '$input'" if $input ne '';
        }
    }
}

main();
```

## 実行例とデモ

このスクリプトを`editor.pl`として保存し、実行してみましょう。

```bash
$ perl editor.pl
```

以下は実行例です。

```
=== 簡易テキストエディタ ===
コマンド: i(挿入), d(削除), u(undo), r(redo), p(表示), q(終了)

> p
テキスト: ''

> i
挿入位置: 0
挿入文字列: Hello
テキスト: 'Hello'

> i
挿入位置: 5
挿入文字列:  World
テキスト: 'Hello World'

> i
挿入位置: 11
挿入文字列: !
テキスト: 'Hello World!'

> p
テキスト: 'Hello World!'

> u
Undo実行
テキスト: 'Hello World'

> u
Undo実行
テキスト: 'Hello'

> r
Redo実行
テキスト: 'Hello World'

> d
削除開始位置: 5
削除文字数: 6
テキスト: 'Hello'

> u
Undo実行
テキスト: 'Hello World'

> q
終了します。
```

対話的に操作でき、Undo/Redoも正しく動作していることが確認できます。

## エラー処理のデモ

エラー処理も確認してみましょう。

```
> i
挿入位置: 100
エラー: 位置は0〜0の範囲で指定してください

> d
エラー: テキストが空です

> u
Undoする操作がありません

> r
Redoする操作がありません
```

範囲外の入力やスタックが空の場合に、適切なエラーメッセージが表示されます。

## 今回作成した完成コード

上記の完成したエディタスクリプトが、今回の完成コードです。

このスクリプトには、これまでのシリーズで作成した以下のクラスがすべて含まれています。

| クラス | 役割 |
|:-------|:-----|
| Editor | テキストを保持する |
| Command::Role | コマンドの共通インターフェース |
| InsertCommand | 文字列を挿入する |
| DeleteCommand | 文字列を削除する |
| MacroCommand | 複数のコマンドをまとめる |
| History | Undo/Redo履歴を管理する |

そして、対話的なCLIインターフェースを追加しました。

## まとめ

- これまで作成した全クラスを統合し、対話型エディタを完成させた
- 対話ループでユーザー入力を受け付け、各コマンドに振り分ける
- 入力値の検証を行い、エラー時は適切なメッセージを表示する
- Undo/Redoスタックが空の場合もハンドリングする

## 次回予告

対話型エディタが完成しました！

次回は最終回として、これまで作ってきたエディタの設計が**実はあるデザインパターンだった**ことをお話しします。シリーズ全体を振り返り、学んだことを整理します。

お楽しみに。
