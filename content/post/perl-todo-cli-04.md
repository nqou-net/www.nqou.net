---
title: "第4回-ファイルからタスクを読み込む - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - file-io
  - moo
description: "Perlのopenでファイルを読み込み、while文とダイヤモンド演算子で行ごと処理。保存されたタスクをTaskオブジェクトとして復元します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第4回です。今回は、保存したファイルからタスクを読み込み、Taskオブジェクトの配列として復元する処理を実装します。

## 前回の振り返り

前回は、Taskクラスを設計し、`open`の書き込みモードでタスクをファイルに保存しました。

{{< linkcard "/post/perl-todo-cli-03/" >}}

`to_line`メソッドでタスクをタブ区切りの1行形式に変換し、UTF-8エンコーディングでファイルに書き込みました。今回は、この保存したファイルを読み込んで、Taskオブジェクトとして復元します。

## openの読み込みモード

ファイルを読み込むには、`open`関数の読み込みモードを使用します。書き込みモードでは`>`を使いましたが、読み込みモードでは`<`を使います。

```perl
# load_tasks.pl
# Perl 5.40+
# 外部依存: Moo

use strict;
use warnings;
use lib 'lib';
use Task;

my $file = 'tasks.txt';

open my $fh, '<:encoding(UTF-8)', $file
    or die "Cannot open $file: $!";

my @tasks;

while (my $line = <$fh>) {
    chomp $line;
    my ($id, $done, $title) = split /\t/, $line;
    push @tasks, Task->new(
        id    => $id,
        title => $title,
        done  => $done,
    );
}

close $fh;

print "Loaded " . scalar(@tasks) . " tasks from $file\n";

for my $task (@tasks) {
    my $status = $task->done ? '[x]' : '[ ]';
    print "$status " . $task->id . ". " . $task->title . "\n";
}
```

このコードのポイントを解説します。

- `open my $fh, '<:encoding(UTF-8)', $file`で読み込み用にファイルを開く
- `<`は読み込みモードを表す
- `:encoding(UTF-8)`で書き込み時と同じエンコーディングを指定する
- `while (my $line = <$fh>)`で1行ずつ読み込む
- `split /\t/, $line`でタブ区切りのデータを分割する
- `Task->new`でTaskオブジェクトを生成し、配列に追加する

`<$fh>`はダイヤモンド演算子（正確にはreadline演算子）と呼ばれ、ファイルハンドルから1行を読み取ります。ファイルの終端に達すると`undef`を返すため、`while`ループが自然に終了します。

## 行ごと処理とTaskオブジェクト生成

`while (<$fh>)`のパターンは、Perlでファイルを行ごとに処理する際の定番イディオムです。ここでは、その動作をより詳しく見てみましょう。

```perl
# parse_task_line.pl
# Perl 5.40+
# 外部依存: Moo

use strict;
use warnings;
use lib 'lib';
use Task;

# ファイルに保存された形式の例
my @lines = (
    "1\t0\t牛乳を買う",
    "2\t1\tレポートを書く",
    "3\t0\t部屋を掃除する",
);

my @tasks;

for my $line (@lines) {
    # タブで分割して各フィールドを取得
    my ($id, $done, $title) = split /\t/, $line;

    # Taskオブジェクトを生成
    my $task = Task->new(
        id    => $id,
        title => $title,
        done  => $done,
    );

    push @tasks, $task;
}

# 復元したタスクを表示
for my $task (@tasks) {
    my $status = $task->done ? '[x]' : '[ ]';
    print "$status " . $task->id . ". " . $task->title . "\n";
}

# 出力:
# [ ] 1. 牛乳を買う
# [x] 2. レポートを書く
# [ ] 3. 部屋を掃除する
```

このコードのポイントを解説します。

- `split /\t/, $line`はタブ文字を区切りとして文字列を分割する
- 分割結果はリストとして返され、複数の変数に一度に代入できる
- 第3回で定義した`to_line`メソッドの逆操作を行っている
- `Task->new`に各フィールドを渡してオブジェクトを再構築する

`split`の第1引数は正規表現パターンです。`/\t/`はタブ文字1つにマッチします。第3回で`join("\t", ...)`で保存したデータを、ここで`split /\t/`で復元しています。この対称性を意識しておくと、データの永続化処理が理解しやすくなります。

## ファイルが存在しない場合の対処

アプリケーションを初めて起動したとき、まだタスクファイルが存在しない場合があります。このケースを適切に処理する必要があります。

`open`に失敗すると、`or die`でプログラムが終了してしまいます。しかし、初回起動時はファイルがないのが正常な状態です。この場合は、空の配列を返すように処理を変更します。

```perl
sub load_tasks {
    my ($file) = @_;

    # ファイルが存在しない場合は空配列を返す
    return [] unless -e $file;

    open my $fh, '<:encoding(UTF-8)', $file
        or die "Cannot open $file: $!";

    my @tasks;
    while (my $line = <$fh>) {
        chomp $line;
        my ($id, $done, $title) = split /\t/, $line;
        push @tasks, Task->new(
            id    => $id,
            title => $title,
            done  => $done,
        );
    }
    close $fh;

    return \@tasks;
}
```

`-e $file`はファイルテスト演算子で、ファイルが存在するかどうかを確認します。存在しない場合は`unless`節により早期リターンして、空の配列リファレンスを返します。

- `-e`はファイルの存在を確認するテスト演算子である
- `unless`は`if`の否定形で、条件が偽の場合に実行される
- `return []`で空の配列リファレンスを返す

この処理により、アプリケーションは初回起動時でもエラーにならず、空のタスクリストから開始できます。

## 次回予告

次回は、ファイルベースのデータ管理の限界について考え、データベース（SQLite）への移行を始めます。なぜデータベースが必要になるのか、その理由を解説します。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. **第4回 - ファイルからタスクを読み込む**（この記事）
5. 第5回 - ファイル版の限界とデータベースへの移行（予定）
6. 第6回 - タスクをデータベースに追加する（予定）
7. 第7回 - タスク一覧を表示する（予定）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
