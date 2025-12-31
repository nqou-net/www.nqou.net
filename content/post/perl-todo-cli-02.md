---
title: "第2回-ユーザーからの入力を受け取る - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - cli
  - stdin
description: "PerlのSTDINでユーザー入力を受け取る方法を解説。chompで改行を除去し、対話型CLIアプリのメニュー表示と選択処理を実装します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第2回です。今回は、ユーザーからの入力を受け取る処理を実装し、対話型のメニューUIを作成します。

## 前回の振り返り

前回は、TODOアプリの完成イメージとTodoAppクラスの骨格を設計しました。

{{< linkcard "/post/perl-todo-cli-01/" >}}

`has tasks`でタスク一覧を保持し、`run`メソッドで処理を実行する設計でした。今回は、この`run`メソッドを実装して、ユーザーと対話できるようにします。

## STDINとは

`STDIN`は、Standard Input（標準入力）の略で、プログラムがユーザーからの入力を受け取るための仕組みです。

Perlでは、`<STDIN>`という記法でユーザーの入力を1行読み取ることができます。ターミナルでプログラムを実行すると、`<STDIN>`はキーボードからの入力を待ち、Enterキーが押されるまでの文字列を返します。

- `<STDIN>`はファイルハンドルからの読み込み演算子である
- 入力がない場合、ユーザーが入力するまでプログラムは待機する
- 読み取った文字列には改行文字（`\n`）が含まれる

この「改行文字が含まれる」という点は重要です。後ほど`chomp`関数で対処します。

## メニュー表示と入力ループ

それでは、TodoAppクラスに`run`メソッドを実装していきます。ユーザーにメニューを表示し、選択を受け付けるループを作成します。

```perl
# lib/TodoApp.pm
# Perl 5.40+
# 外部依存: Moo

package TodoApp;
use Moo;

has tasks => (
    is      => 'rw',
    default => sub { [] },
);

sub run {
    my $self = shift;

    while (1) {
        $self->show_menu;
        print "選択してください: ";
        my $input = <STDIN>;

        # 入力がなければ終了（Ctrl+Dなど）
        last unless defined $input;

        chomp $input;

        if ($input eq '1') {
            print "タスクを追加します（未実装）\n";
        }
        elsif ($input eq '2') {
            print "タスク一覧を表示します（未実装）\n";
        }
        elsif ($input eq '3') {
            print "タスクを完了にします（未実装）\n";
        }
        elsif ($input eq '4') {
            print "タスクを削除します（未実装）\n";
        }
        elsif ($input eq '0') {
            print "終了します\n";
            last;
        }
        else {
            print "無効な選択です。0-4の数字を入力してください。\n";
        }
    }
}

sub show_menu {
    my $self = shift;
    print "\n";
    print "=== TODO リスト ===\n";
    print "1. タスクを追加\n";
    print "2. タスク一覧\n";
    print "3. タスクを完了\n";
    print "4. タスクを削除\n";
    print "0. 終了\n";
}

1;
```

このコードのポイントを解説します。

- `while (1)`で無限ループを作り、ユーザーが終了を選ぶまで繰り返す
- `<STDIN>`でユーザーの入力を1行読み取る
- `defined $input`でEOF（End of File）をチェックする
- `chomp $input`で末尾の改行を削除する
- `if-elsif-else`で入力値に応じた処理を分岐する

`defined`によるチェックは、ユーザーがCtrl+D（Unix系）やCtrl+Z（Windows）を押した場合に対応するためです。この場合、`<STDIN>`は`undef`を返すため、`defined`でチェックしないとエラーになります。

## chompと入力バリデーション

`<STDIN>`で読み取った文字列には改行文字が含まれています。例えば、ユーザーが「1」と入力してEnterを押すと、実際には「1\n」という文字列が返されます。

`chomp`関数は、この末尾の改行文字を削除します。

```perl
# chomp の動作確認
# Perl 5.40+
# 外部依存: なし

my $input = <STDIN>;

# chomp前: "hello\n"（6文字）
print "chomp前: 長さ=" . length($input) . "\n";

chomp($input);

# chomp後: "hello"（5文字）
print "chomp後: 長さ=" . length($input) . "\n";

# バリデーションの例
if ($input =~ /^[0-4]$/) {
    print "有効な入力: $input\n";
}
else {
    print "無効な入力: $input\n";
}
```

入力のバリデーションでは、正規表現を使うと柔軟な判定ができます。`/^[0-4]$/`は「文字列全体が0から4の1文字である」ことを確認しています。

- `^`は文字列の先頭を表す
- `[0-4]`は0, 1, 2, 3, 4のいずれか1文字を表す
- `$`は文字列の末尾を表す

`chomp`を忘れると、`$input`は「1\n」のままなので、この正規表現にマッチしません。`chomp`は入力処理の基本として覚えておきましょう。

## 次回予告

次回は、追加したタスクをファイルに保存する処理を実装します。データの永続化について学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. **第2回 - ユーザーからの入力を受け取る**（この記事）
3. 第3回 - タスクをファイルに保存する（予定）
4. 第4回 - ファイルからタスクを読み込む（予定）
5. 第5回 - ファイル版の限界とデータベースへの移行（予定）
6. 第6回 - タスクをデータベースに追加する（予定）
7. 第7回 - タスク一覧を表示する（予定）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
