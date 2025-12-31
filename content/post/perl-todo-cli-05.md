---
title: "第5回-ファイル版の限界とデータベースへの移行 - シンプルなTodo CLIアプリ"
draft: true
tags:
  - perl
  - dbi
  - sqlite
  - singleton
description: "ファイル保存の限界を体感し、PerlでSQLiteデータベースに接続。DBハンドルをSingletonパターンで一元管理する方法を解説します。"
---

[@nqounet](https://x.com/nqounet)です。

「シンプルなTodo CLIアプリ」シリーズの第5回です。今回は、ファイルベースのデータ管理の限界を確認し、SQLiteデータベースへの移行を始めます。

## 前回の振り返り

前回は、`open`の読み込みモードでファイルからタスクを復元する処理を実装しました。

{{< linkcard "/post/perl-todo-cli-04/" >}}

ダイヤモンド演算子（`<$fh>`）で行ごとに読み込み、`split`でパースしてTaskオブジェクトを生成しました。これでファイルへの保存と読み込みが完成しましたが、実際に使っていくと問題が見えてきます。

## ファイル保存の限界

ファイルベースのデータ管理には、いくつかの困難があります。

### 検索の困難さ

「未完了のタスクだけを表示したい」という要件を考えてみましょう。ファイルベースでは、以下のような処理が必要です。

- ファイル全体を読み込む
- 各行をパースしてTaskオブジェクトを生成する
- `done`フラグが`0`のものだけをフィルタする

タスクが100件あっても1000件あっても、必ずファイル全体を読み込む必要があります。

### 更新の困難さ

「ID=5のタスクを完了にしたい」という要件を考えてみましょう。ファイルベースでは、以下のような処理が必要です。

- ファイル全体を読み込む
- 各行をパースする
- ID=5の行を見つけて`done`フラグを更新する
- ファイル全体を書き直す

1件の更新のために、ファイル全体を読み書きする必要があります。タスクが増えるほど非効率になります。

### 同時アクセスの問題

複数のプロセスが同時にファイルを操作すると、データが壊れる可能性があります。ファイルロックで対処できますが、実装が複雑になります。

これらの問題を解決するのが、データベースです。

## SQLiteとDBIの紹介

SQLiteは、ファイルベースの軽量なデータベースです。サーバープロセスが不要で、1つのファイル（例: `todo.db`）にすべてのデータが格納されます。

DBIは、Perlからデータベースにアクセスするための標準インターフェースです。DBIを使うと、SQLite、MySQL、PostgreSQLなど様々なデータベースに同じコードでアクセスできます。

DBIの詳細については、以下の記事も参考にしてください。

{{< linkcard "/2025/12/13/000000/" >}}

SQLiteとDBIを使うには、以下のモジュールが必要です。

- DBI: データベースアクセスの標準インターフェース
- DBD::SQLite: SQLite用のドライバ

`cpanfile`に依存関係を記述しておきましょう。

```perl
# cpanfile
requires 'DBI', '1.643';
requires 'DBD::SQLite', '1.74';
```

## DBI接続とSingletonパターン

データベースに接続するには、`DBI->connect`メソッドを使用します。ここで重要なのは、DBハンドル（`$dbh`）をアプリケーション全体で1つだけ保持する設計です。

DBハンドルを毎回`connect`で生成するのは非効率です。また、接続を一箇所で管理することで、設定変更や接続エラーの対処が容易になります。この「インスタンスを1つだけ保持する」設計パターンを、Singletonパターンと呼びます。

Perlでは、クロージャを使ってSingletonパターンを簡潔に実装できます。

```perl
# lib/DB.pm
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

package DB;
use strict;
use warnings;
use DBI;

{
    my $dbh;

    sub get_dbh {
        return $dbh if $dbh;

        $dbh = DBI->connect(
            'dbi:SQLite:dbname=todo.db',
            '', '',
            {
                RaiseError => 1,
                PrintError => 0,
                AutoCommit => 1,
                sqlite_unicode => 1,
            }
        );

        return $dbh;
    }
}

1;
```

このコードのポイントを解説します。

- ブロック `{ }` の中で `my $dbh` を宣言し、外部からアクセスできないようにする
- `get_dbh`サブルーチンは、このブロック内の`$dbh`を参照できる（クロージャ）
- 初回呼び出し時のみ`DBI->connect`で接続し、以降は同じハンドルを返す
- `RaiseError => 1`で、エラー時に自動的に`die`する
- `PrintError => 0`で、エラーメッセージの二重出力を防ぐ
- `AutoCommit => 1`で、各SQL文を自動的にコミットする
- `sqlite_unicode => 1`で、UTF-8の日本語を正しく扱う

この`get_dbh`を使うと、どこからでも同じDBハンドルにアクセスできます。

```perl
use DB;

my $dbh = DB::get_dbh();
# 以降、$dbhを使ってSQL操作を行う
```

## テーブル作成

データベースに接続できたら、タスクを保存するテーブルを作成します。テーブルとは、データを格納する「表」のことです。

Taskクラスの属性（`id`、`title`、`done`）に対応するカラム（列）を定義します。

```perl
# scripts/create_table.pl
# Perl 5.40+
# 外部依存: DBI, DBD::SQLite

use strict;
use warnings;
use lib 'lib';
use DB;

my $dbh = DB::get_dbh();

$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS tasks (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    done  INTEGER DEFAULT 0
)
SQL

print "Table 'tasks' created successfully.\n";
```

このコードのポイントを解説します。

- `$dbh->do`は、結果を返さないSQL文（DDL）を実行する
- `CREATE TABLE IF NOT EXISTS`で、テーブルが存在しない場合のみ作成する
- `id INTEGER PRIMARY KEY AUTOINCREMENT`で、自動採番の主キーを定義する
- `title TEXT NOT NULL`で、タスクのタイトルを必須項目として定義する
- `done INTEGER DEFAULT 0`で、完了フラグを定義（デフォルトは未完了）
- ヒアドキュメント（`<<'SQL'`）で複数行のSQL文を見やすく記述する

このスクリプトを実行すると、`todo.db`ファイルが作成され、その中に`tasks`テーブルが定義されます。

```bash
$ perl scripts/create_table.pl
Table 'tasks' created successfully.
```

これで、データベースへの移行準備が整いました。ファイルベースでは困難だった検索・更新も、SQLを使えば効率的に実行できます。

## 次回予告

次回は、タスクをデータベースに追加する処理（Create操作）を実装します。`INSERT`文とプレースホルダについて学びましょう。

## シリーズ一覧

1. [第1回 - 完成イメージとMoo設計](/post/perl-todo-cli-01/)
2. [第2回 - ユーザーからの入力を受け取る](/post/perl-todo-cli-02/)
3. [第3回 - タスクをファイルに保存する](/post/perl-todo-cli-03/)
4. [第4回 - ファイルからタスクを読み込む](/post/perl-todo-cli-04/)
5. **第5回 - ファイル版の限界とデータベースへの移行**（この記事）
6. 第6回 - タスクをデータベースに追加する（予定）
7. 第7回 - タスク一覧を表示する（予定）
8. 第8回 - タスクを完了にする（予定）
9. 第9回 - タスクを削除する（予定）
10. 第10回 - コマンドライン引数でサクサク操作（予定）
