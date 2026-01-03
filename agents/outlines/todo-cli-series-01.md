# シンプルなTodo CLIアプリ 第1回 - アウトライン

**作成日**: 2026年1月1日  
**対象記事**: シリーズ「シンプルなTodo CLIアプリ」第1回  
**対象読者**: Perl入学式卒業程度、「Mooで覚えるオブジェクト指向プログラミング」を読了した方  
**ペルソナ**: Perlの基礎とMooを習得し、実践的なアプリケーション開発に挑戦したい人  
**目標**: if-elsif分岐で動作する最もシンプルなTodo CLIアプリを作成し、その限界を理解する

---

## 前提シリーズとの関連

「Mooで覚えるオブジェクト指向プログラミング」シリーズ（全12回）の続編として位置づけ。

**前提シリーズ最終回リンク**: `/2025/12/30/163820/`（第12回-型チェックでバグを未然に防ぐ）

---

## タイトル候補

「Perl CLI入門｜まずは動くTodoアプリを作ろう - if文で始めるシンプル実装」

---

## 要約（1行）

Perlでコマンドライン引数を処理し、if-elsif分岐でadd/list/completeのサブコマンドを実装する、最もシンプルなTodo CLIアプリを作成します。

---

## meta description（160文字以内）

Perlで実践的なCLIアプリを作ってみませんか？if-elsif分岐でadd・list・completeの3つのサブコマンドを持つTodoアプリを実装。配列でタスクを管理するシンプルな構成から始め、動くアプリを通じて拡張性の課題を体感します。

---

## 推奨タグ

- `perl`
- `cli`
- `todo-app`
- `perl-tutorial`

---

## H2/H3 見出し構造

### H2: はじめに - Mooの次は実践アプリを作ろう

- 「Mooで覚えるオブジェクト指向」シリーズを終えた方へ
- このシリーズのゴール：CLIアプリ開発を通じて設計を学ぶ
- 第1回の目標：「動くTodoアプリ」を素朴に実装する

### H2: 今回作るもの - 3つのコマンドを持つTodo CLI

#### H3: 完成イメージ

- `todo add "牛乳を買う"` でタスク追加
- `todo list` でタスク一覧表示
- `todo complete 1` でタスク完了

#### H3: 最小限の機能で始める

- まずは動くことを最優先
- 拡張性やエラー処理は後の回で

### H2: 環境の準備

#### H3: 必要なもの

- Perl 5.16以上
- テキストエディタ
- ターミナル

#### H3: ファイル構成

- `todo.pl` - メインスクリプト
- 今回は1ファイルで完結

### H2: コマンドライン引数を受け取る

#### H3: @ARGVとは

- コマンドライン引数が格納される特殊変数
- `perl todo.pl add "牛乳を買う"` → `@ARGV = ('add', '牛乳を買う')`

#### H3: サブコマンドを取り出す

- `shift @ARGV` で最初の引数を取得
- サブコマンド（add/list/complete）を判定する準備

### H2: if-elsif分岐でサブコマンドを実装する

#### H3: 基本構造

```perl
my $command = shift @ARGV // 'help';

if ($command eq 'add') {
    # タスク追加
}
elsif ($command eq 'list') {
    # 一覧表示
}
elsif ($command eq 'complete') {
    # 完了処理
}
else {
    # ヘルプ表示
}
```

#### H3: なぜif-elsifから始めるのか

- 最もシンプルで理解しやすい
- 後の回で「なぜ改善が必要か」を実感するため

### H2: 配列でタスクを管理する

#### H3: タスクの保存と読み込み

- テキストファイルに1行1タスクで保存
- 起動時にファイルから読み込み

#### H3: ファイル操作の基本

- `open` でファイルハンドルを取得
- 読み込み・書き込みの方法

### H2: add - タスクを追加する

#### H3: 引数からタスク内容を取得

- `shift @ARGV` でタスク文字列を取得
- 空文字チェック

#### H3: ファイルに追記する

- `>>` モードでファイルを開く
- 1行追記して閉じる

#### H3: 動作確認

- `perl todo.pl add "牛乳を買う"`
- ファイルの中身を確認

### H2: list - タスク一覧を表示する

#### H3: ファイルから読み込む

- `<` モードでファイルを開く
- 1行ずつ読み込んで表示

#### H3: 番号付きで表示する

- インデックスを付けて出力
- `1. 牛乳を買う` の形式

#### H3: 動作確認

- `perl todo.pl list`
- 追加したタスクが表示されることを確認

### H2: complete - タスクを完了する

#### H3: 番号でタスクを指定

- `shift @ARGV` で番号を取得
- 配列のインデックスとして使用

#### H3: 指定したタスクを削除

- `splice` で配列から削除
- ファイルを書き直す

#### H3: 動作確認

- `perl todo.pl complete 1`
- 一覧から消えていることを確認

### H2: 完成コード - 全体を見てみよう

#### H3: todo.pl の全容

- 約40-50行のシンプルなスクリプト
- コピペで動作確認できる完全なコード

#### H3: 動かしてみよう

- 一連の操作を実行
- add → list → complete → list の流れ

### H2: このコードの問題点 - 拡張性の壁

#### H3: コマンドが増えたらどうなる？

- if-elsif が長大化する
- 新しいコマンドを追加するたびに条件分岐を修正

#### H3: テストが書きにくい

- 処理がスクリプト直下に書かれている
- 単体テストが困難

#### H3: コードの重複

- ファイル操作が各所に散らばる
- DRY原則に反する

### H2: 次回予告 - サブルーチンで整理する

- 今回の問題点をサブルーチンで解決
- 責務を分離してテスト可能なコードへ

### H2: まとめ

- if-elsif分岐で動くTodo CLIを作成した
- 配列とファイルでタスクを永続化した
- シンプルだが拡張性に課題があることを確認

---

## コード例1: if-elsif分岐でadd/list/completeを実装

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

my $file = 'todo.txt';
my $command = shift @ARGV // 'help';

if ($command eq 'add') {
    my $task = shift @ARGV;
    die "Usage: $0 add <task>\n" unless defined $task && $task ne '';
    
    open my $fh, '>>', $file or die "Cannot open $file: $!";
    print $fh "$task\n";
    close $fh;
    
    print "Added: $task\n";
}
elsif ($command eq 'list') {
    unless (-e $file) {
        print "No tasks.\n";
        exit;
    }
    
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my @tasks = <$fh>;
    close $fh;
    
    chomp @tasks;
    my $i = 1;
    for my $task (@tasks) {
        print "$i. $task\n";
        $i++;
    }
}
elsif ($command eq 'complete') {
    my $num = shift @ARGV;
    die "Usage: $0 complete <number>\n" unless defined $num && $num =~ /^\d+$/;
    
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my @tasks = <$fh>;
    close $fh;
    
    chomp @tasks;
    my $index = $num - 1;
    die "Task $num not found.\n" if $index < 0 || $index >= @tasks;
    
    my $completed = splice @tasks, $index, 1;
    
    open $fh, '>', $file or die "Cannot open $file: $!";
    print $fh "$_\n" for @tasks;
    close $fh;
    
    print "Completed: $completed\n";
}
else {
    print "Usage: $0 <command> [args]\n";
    print "Commands:\n";
    print "  add <task>      - Add a new task\n";
    print "  list            - List all tasks\n";
    print "  complete <num>  - Complete a task by number\n";
}
```

---

## コード例2: 配列でタスクを管理するシンプルな実装（読み書き部分の抜粋）

```perl
# タスクをファイルから読み込む
sub load_tasks {
    my $file = shift;
    return () unless -e $file;
    
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my @tasks = <$fh>;
    close $fh;
    
    chomp @tasks;
    return @tasks;
}

# タスクをファイルに保存する
sub save_tasks {
    my ($file, @tasks) = @_;
    
    open my $fh, '>', $file or die "Cannot open $file: $!";
    print $fh "$_\n" for @tasks;
    close $fh;
}

# 使用例
my @tasks = load_tasks('todo.txt');
push @tasks, '新しいタスク';
save_tasks('todo.txt', @tasks);
```

---

## 記事の想定ボリューム

- 本文: 約2,500〜3,000文字
- コード: 約50〜60行
- 読了時間: 約10分

---

## SEO観点でのポイント

1. **タイトル**: 「Perl CLI入門」「Todoアプリ」という検索されやすいキーワードを含む
2. **meta description**: 具体的な機能（add/list/complete）を明示し、クリック誘導
3. **見出し構造**: 「〜を作る」「〜を実装する」という動詞形で読者の行動を促進
4. **前提シリーズへのリンク**: 内部リンクでSEO評価向上と読者の回遊促進
5. **次回予告**: 連載記事としての継続読了を促進

---

## ドキュメント情報

- **作成日**: 2026年1月1日
- **バージョン**: 1.0
- **作成者**: search-engine-optimization エージェント
- **ステータス**: 完了
