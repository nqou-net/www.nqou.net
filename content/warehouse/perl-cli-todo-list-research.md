---
title: "調査ドキュメント: PerlでTODOリスト（CLI）を作成するシリーズ記事"
description: "シリーズ記事「PerlでTODOリスト（CLI）を作成する」の連載構造案を作成するための調査結果"
date: 2025-12-30
draft: true
tags:
  - perl
  - cli
  - todo-list
  - dbi
  - sqlite
  - research
---

## 調査概要

### 調査目的

シリーズ記事「PerlでTODOリスト（CLI）を作成する」の連載構造案を作成するための情報収集と調査を行う。

### 調査対象

- Perl入学式卒業程度の読者を想定
- データベースを用いたCRUDの実装
- ファイルの入出力も途中で扱う
- 各回の記事につき「コード例は2つまで」
- 各回ごとに導入する「新しい概念」は1つまで

### 調査実施日

2025-12-30

---

## 1. Perl入学式のカリキュラム調査

### 要点

Perl入学式は、プログラミング初心者やPerl未経験者向けの勉強会である。環境構築からPerlの基礎、簡単なウェブアプリケーション作成までを体系的に学べる内容になっている。

### 主なカリキュラム内容

1. **Perlの紹介**: Perl言語の特徴や用途、基本的な文法
2. **環境構築**: Windows/Mac/Linux環境でPerlをインストール
3. **基礎文法**: 変数・演算子・制御構造（if, for, whileなど）
4. **標準入力・出力とファイル操作**: ユーザーからの入力、結果表示、テキストファイルの読み書き
5. **データ構造**: 配列・ハッシュの使い方
6. **サブルーチン（関数）の作成と活用**: コードの部品化と利用
7. **正規表現の基礎**: 文字列処理の要となるPerlの強力な機能
8. **練習問題／演習**: 実際の課題に取り組みながら、理解を深める
9. **簡単なWebアプリケーション構築**: 実践的なプログラム作成

### 想定読者の既知事項

- 変数（スカラー、配列、ハッシュ）
- 制御構造（if, for, while）
- サブルーチンの基本
- 正規表現の基礎
- 標準入出力の基本

### 出典

- Perl入学式公式サイト: https://www.perl-entrance.org/about.html
- Perl入学式の教科書（GitHub）: https://github.com/perl-entrance-org/Perl-Entrance-Textbook
- Perl入学式 in東京 2024: https://perl-entrance.connpass.com/event/345025/

### 信頼度

高（公式情報源）

---

## 2. Perl CLI アプリケーション開発

### 要点

PerlでCLIアプリケーションを開発する際は、以下の要素が重要である：

1. **コマンドライン引数処理**: `Getopt::Long` モジュールが標準
2. **ユーザー入力処理**: `<STDIN>` による対話的入力
3. **出力フォーマット**: 見やすい出力形式の設計
4. **エラーハンドリング**: 適切なエラーメッセージ

### Getopt::Long の特徴

- Perl標準モジュール（追加インストール不要）
- 短いオプション（`-v`）と長いオプション（`--verbose`）を両方サポート
- オプションの型指定（文字列、整数、フラグなど）
- サブコマンドの実装も可能

### 根拠

リポジトリ内の記事「Perlでのコマンドライン引数処理 - Getopt::Long」（`/2025/12/21/000000/`）で詳しく解説されている。

### 出典

- 内部記事: /2025/12/21/000000/ (Getopt::Long)
- MetaCPAN: https://metacpan.org/pod/Getopt::Long

### 信頼度

高（公式ドキュメントおよび内部記事）

---

## 3. Perl ファイル入出力

### 要点

Perlでのファイル入出力は `open` 関数を使用する。UTF-8エンコーディングへの対応が重要である。

### 基本パターン

```perl
# 読み込み（UTF-8対応）
open my $fh, '<:encoding(UTF-8)', $filename or die "Cannot open: $!";

# 書き込み（UTF-8対応）
open my $fh, '>:encoding(UTF-8)', $filename or die "Cannot open: $!";

# 追記
open my $fh, '>>:encoding(UTF-8)', $filename or die "Cannot open: $!";
```

### モダンなアプローチ: Path::Tiny

```perl
use Path::Tiny;

# 読み込み
my $content = path('file.txt')->slurp_utf8;

# 書き込み
path('file.txt')->spew_utf8($content);
```

### 根拠

- 3引数形式の `open` がセキュリティ上推奨される
- 日本語を扱う場合は必ず文字コード指定（UTF-8）が必要

### 出典

- Perlゼミ: https://perlzemi.com/books/linux/chapter05.html
- perldoc.jp: https://perldoc.jp/
- 内部記事: /2025/12/03/041603/ (CPAN20選 - Path::Tiny)

### 信頼度

高（公式ドキュメントおよび技術ブログ）

---

## 4. Perl データベース操作（DBI / SQLite）

### 要点

PerlでのデータベースアクセスにはDBIモジュールが標準である。SQLiteはファイルベースで軽量なので学習・小規模プロジェクトに最適。

### DBI + SQLite の基本

```perl
use DBI;

# 接続
my $dbh = DBI->connect(
    'dbi:SQLite:dbname=todo.db',
    '', '',
    { RaiseError => 1, AutoCommit => 1 }
);

# テーブル作成
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
});
```

### CRUD操作

| 操作 | SQL | Perlメソッド |
|------|-----|-------------|
| Create | INSERT | `$dbh->prepare()` + `$sth->execute()` |
| Read | SELECT | `$sth->fetchrow_hashref()` |
| Update | UPDATE | `$dbh->prepare()` + `$sth->execute()` |
| Delete | DELETE | `$dbh->prepare()` + `$sth->execute()` |

### 重要なポイント

- **プレースホルダ使用が必須**: SQLインジェクション対策
- **RaiseError => 1**: エラー時に例外を投げる
- **AutoCommit**: トランザクション制御

### 根拠

リポジトリ内の記事「Perlでのデータベース操作 — DBI / DBIx::Class 入門」（`/2025/12/13/000000/`）で詳しく解説されている。

### 出典

- 内部記事: /2025/12/13/000000/ (DBI/DBIx::Class入門)
- MetaCPAN DBI: https://metacpan.org/pod/DBI
- MetaCPAN DBD::SQLite: https://metacpan.org/pod/DBD::SQLite
- perldoc.jp: https://perldoc.jp/docs/modules/DBD-SQLite-1.29/SQLite.pod

### 信頼度

高（公式ドキュメントおよび内部記事）

---

## 5. CRUD操作の実装パターン

### 要点

TODOリストにおけるCRUD操作は以下のパターンで実装する：

### Create（タスク追加）

```perl
my $sth = $dbh->prepare('INSERT INTO tasks (title) VALUES (?)');
$sth->execute($title);
my $id = $dbh->last_insert_id(undef, undef, 'tasks', 'id');
```

### Read（タスク一覧・詳細）

```perl
# 全件取得
my $sth = $dbh->prepare('SELECT * FROM tasks ORDER BY created_at DESC');
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    print "[$row->{id}] $row->{title}\n";
}

# 条件付き
my $sth = $dbh->prepare('SELECT * FROM tasks WHERE done = ?');
$sth->execute(0); # 未完了のみ
```

### Update（タスク更新・完了）

```perl
my $sth = $dbh->prepare('UPDATE tasks SET done = 1 WHERE id = ?');
$sth->execute($id);
```

### Delete（タスク削除）

```perl
my $sth = $dbh->prepare('DELETE FROM tasks WHERE id = ?');
$sth->execute($id);
```

### 仮定

- 各操作は独立した関数として実装する
- エラーハンドリングは `Try::Tiny` を使用

### 出典

- 内部記事: /2025/12/13/000000/ (DBI/DBIx::Class入門)
- 内部記事: /2025/12/14/000000/ (Try::Tiny)

### 信頼度

高（内部記事に基づく）

---

## 6. 競合記事の分析

### 日本語の競合記事

#### 1. Perlゼミ - ファイルの読み書き

- **URL**: https://perlzemi.com/books/linux/chapter05.html
- **特徴**: 基礎から丁寧に解説、初心者向け
- **差別化ポイント**: TODOアプリという具体的なプロジェクトを通じた実践的学習

#### 2. KENT-WEB - PerlでSQLite

- **URL**: https://www.kent-web.com/perl/sqlite/step02.html
- **特徴**: SQLiteの設定入門
- **差別化ポイント**: CLI操作とデータベースの組み合わせを段階的に学習

#### 3. プログラミング雑ネタ集 - PerlでSQLiteを使う

- **URL**: https://azisava.sakura.ne.jp/programming/0005.html
- **特徴**: 実用的なサンプルコード
- **差別化ポイント**: 連載形式で1記事1概念の原則を守る

### 英語の競合記事

#### 1. GitHub - TODO-in-perl

- **URL**: https://github.com/Sumit4codes/TODO-in-perl
- **特徴**: シンプルなCLI TODOアプリの実装
- **差別化ポイント**: 日本語での解説、段階的な学習パス

#### 2. GitHub - mnestorov/todo-list

- **URL**: https://github.com/mnestorov/todo-list
- **特徴**: 優先度や期限などの高度な機能
- **差別化ポイント**: Perl入学式卒業生向けの難易度設定

### 本シリーズの差別化ポイント

1. **Perl入学式卒業程度の読者に最適化**: 既知事項を前提とした解説
2. **段階的な学習パス**: ファイル保存→データベース保存への移行
3. **1記事1概念の原則**: 消化しやすい分量
4. **各回コード例2つまで**: 集中できる内容
5. **日本語での丁寧な解説**: 英語リソースへのアクセス障壁を解消

---

## 7. 内部リンク候補（関連記事）

### grepによる調査結果

以下のキーワードで `/content/post` 配下を検索した結果：

### DBI関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/13/000000.md | /2025/12/13/000000/ | Perlでのデータベース操作 — DBI / DBIx::Class 入門 |
| /content/post/2025/12/03/041603.md | /2025/12/03/041603/ | CPANとは — 実務で役立つCPANモジュール20選（DBIを含む） |

### SQLite関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/13/000000.md | /2025/12/13/000000/ | Perlでのデータベース操作（SQLite例を含む） |

### CLI / コマンドライン関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/21/000000.md | /2025/12/21/000000/ | Perlでのコマンドライン引数処理 - Getopt::Long |
| /content/post/2025/12/25/000000.md | /2025/12/25/000000/ | Perl Advent Calendar 2025 完走！（全体まとめ） |

### ファイル入出力 / open関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/03/041603.md | /2025/12/03/041603/ | Path::Tiny（ファイル操作の定番） |
| /content/post/2025/12/14/000000.md | /2025/12/14/000000/ | Try::Tiny（ファイル操作でのエラーハンドリング例） |

### 例外処理関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/14/000000.md | /2025/12/14/000000/ | Try::Tiny - 例外処理をスマートに |

### 並列処理関連

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/16/000000.md | /2025/12/16/000000/ | Parallel::ForkManager |

### Webスクレイピング関連（応用例として）

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/22/000000.md | /2025/12/22/000000/ | Web::Scraper と Mojo::UserAgent |

### 依存関係管理

| ファイル | 内部リンク | 概要 |
|---------|-----------|------|
| /content/post/2025/12/10/000000.md | /2025/12/10/000000/ | Carton/cpanfile - モダンなPerl依存関係管理 |

---

## 8. 技術的正確性を担保するための情報源リスト

### 公式ドキュメント（最優先）

| リソース | URL | 用途 |
|---------|-----|------|
| MetaCPAN DBI | https://metacpan.org/pod/DBI | DBI APIリファレンス |
| MetaCPAN DBD::SQLite | https://metacpan.org/pod/DBD::SQLite | SQLite固有の機能 |
| MetaCPAN Getopt::Long | https://metacpan.org/pod/Getopt::Long | CLI引数処理 |
| MetaCPAN Try::Tiny | https://metacpan.org/pod/Try::Tiny | 例外処理 |
| MetaCPAN Path::Tiny | https://metacpan.org/pod/Path::Tiny | ファイル操作 |
| perldoc.jp | https://perldoc.jp/ | 日本語訳Perlドキュメント |
| Perl公式ドキュメント | https://perldoc.perl.org/ | Perl言語リファレンス |

### 書籍（推奨）

| 書籍名 | ASIN/ISBN | 用途 |
|--------|-----------|------|
| 初めてのPerl 第7版 | B07DP7W5KS | Perl基礎（ラクダ本） |
| プログラミングPerl 第4版 | 4873116864 | Perl詳細リファレンス |
| モダンPerl入門 | B00M0RM3EG | モダンなPerlプラクティス |

### コミュニティリソース

| リソース | URL | 用途 |
|---------|-----|------|
| Perl入学式教科書 | https://github.com/perl-entrance-org/Perl-Entrance-Textbook | 想定読者の既知事項確認 |
| Perlゼミ | https://perlzemi.com/ | 日本語チュートリアル |
| PerlMonks | https://perlmonks.org/ | Q&A、ベストプラクティス |
| Reddit r/perl | https://www.reddit.com/r/perl/ | 最新の議論 |

### 本ブログ内の関連記事

| 記事 | 内部リンク | 参照目的 |
|------|-----------|---------|
| DBI/DBIx::Class入門 | /2025/12/13/000000/ | データベース操作の詳細 |
| Try::Tiny | /2025/12/14/000000/ | 例外処理パターン |
| Getopt::Long | /2025/12/21/000000/ | CLI引数処理 |
| CPAN20選 | /2025/12/03/041603/ | モジュール選定の参考 |
| Carton/cpanfile | /2025/12/10/000000/ | 依存関係管理 |

---

## 9. 連載構造案への提言

### 推奨する連載の流れ

1. **序章**: TODOリストアプリの概要と完成イメージ
2. **基礎編（ファイル保存）**:
   - ユーザー入力とメニュー表示
   - ファイルへの保存（open/print）
   - ファイルからの読み込み
3. **応用編（データベース保存）**:
   - DBIとSQLiteの導入
   - CRUD操作の実装
   - トランザクションとエラーハンドリング
4. **発展編**:
   - コマンドライン引数（Getopt::Long）
   - 機能拡張（検索、フィルタリング）

### 1記事1概念の原則に基づく分割案

| 回 | 新しい概念 | 内容 |
|----|-----------|------|
| 第1回 | ユーザー入力 | `<STDIN>` でのメニュー選択 |
| 第2回 | ファイル書き込み | `open ... '>'` でタスク保存 |
| 第3回 | ファイル読み込み | `open ... '<'` でタスク復元 |
| 第4回 | DBI接続 | SQLiteへの接続と初期化 |
| 第5回 | INSERT | タスク追加（Create） |
| 第6回 | SELECT | タスク一覧表示（Read） |
| 第7回 | UPDATE | タスク完了（Update） |
| 第8回 | DELETE | タスク削除（Delete） |
| 第9回 | CLI引数 | Getopt::Longでサブコマンド |
| 第10回 | まとめ | 全体のリファクタリング |

### 仮定

- 各回のコード例は2つまでに収める
- Perl入学式卒業生が無理なく理解できる難易度
- 実際に動作するコードを提供する

---

## 10. 調査結論

### 調査により判明した事項

1. **Perl入学式卒業生は基礎文法を習得済み**: 変数、配列、ハッシュ、サブルーチン、正規表現の基本は既知
2. **ファイル入出力→データベースへの移行は自然な学習パス**: 複雑さを段階的に上げられる
3. **既存の関連記事が豊富**: DBI、Try::Tiny、Getopt::Longなどの記事を内部リンクとして活用可能
4. **競合との差別化は「段階的学習」と「1記事1概念」**: 既存のリソースは包括的だが分量が多い

### 次のステップ

連載構造案の作成（3案）を `/content/warehouse/perl-cli-todo-list-structure.md` に作成する。

---

## 更新履歴

- 2025-12-30: 初版作成
