---
title: "シンプルなTodo CLIアプリ シリーズ記事向け調査ドキュメント"
date: 2026-01-01T13:30:00+09:00
draft: false
tags:
  - perl
  - design-patterns
  - command-pattern
  - repository-pattern
  - cli
  - todo-cli
description: "「シンプルなTodo CLIアプリ」をテーマにしたPerl技術シリーズ記事作成のための情報収集結果"
---

# シンプルなTodo CLIアプリ シリーズ記事向け調査ドキュメント

## 調査目的

「シンプルなTodo CLIアプリ」をテーマにしたPerl技術シリーズ記事（連載記事）を作成するための情報収集。

- **調査対象**: Commandパターン、Repositoryパターン、Perl CLI開発、JSON/SQLite永続化
- **想定読者**: Perl入学式卒業程度、「Mooで覚えるオブジェクト指向プログラミング」第12回を読了
- **調査実施日**: 2026年1月1日

---

## 1. Commandパターンについて

### 1.1 概要

**要点**:

- Commandパターンは、リクエスト（操作や命令）をオブジェクトとしてカプセル化する振る舞いパターンである
- リクエストの送信者（Invoker）と受信者（Receiver）を分離し、疎結合な設計を実現する
- CLIアプリケーションでは、各操作（add, list, done, delete）をコマンドオブジェクトとして実装することで拡張性が向上する

**根拠**:

- GoF「Design Patterns」書籍において、Commandパターンは「リクエストをオブジェクトとして扱い、異なるリクエストでクライアントをパラメータ化し、リクエストをキューに入れたり、ログに記録したり、操作の取り消しをサポートする」と定義されている
- 詳細な調査結果は `/content/warehouse/command-pattern.md` を参照

**仮定**:

- Todo CLIアプリケーションでは、Undo/Redo機能を将来的に追加したい場合にCommandパターンが有効
- 小規模なアプリケーションでは過剰設計になる可能性があるため、シリーズ記事では段階的に導入することを推奨

**出典**:

- Wikipedia: Command pattern - https://en.wikipedia.org/wiki/Command_pattern
- GeeksforGeeks: Command Design Pattern - https://www.geeksforgeeks.org/system-design/command-pattern/
- Refactoring Guru: Command - https://refactoring.guru/design-patterns/command
- 既存調査ドキュメント: `/content/warehouse/command-pattern.md`

**信頼度**: 高（GoF原典および複数の信頼できる技術サイト、既存調査ドキュメント）

### 1.2 構成要素

| 要素 | 役割 | Todo CLIでの具体例 |
|-----|------|------------------|
| **Command (インターフェース)** | コマンドの実行メソッド（execute）を宣言 | `Command`ロール（executeメソッドを持つ） |
| **ConcreteCommand** | Commandインターフェースを実装 | `AddCommand`, `ListCommand`, `DoneCommand`, `DeleteCommand` |
| **Receiver** | 実際の処理を知っているオブジェクト | `TodoRepository`（タスクの保存・取得を担当） |
| **Invoker** | コマンドの実行を依頼するオブジェクト | `CLIDispatcher`（コマンドライン引数を解析してコマンドを実行） |
| **Client** | ConcreteCommandオブジェクトを生成 | メインスクリプト（`todo.pl`） |

### 1.3 Perlでの実装例

```perl
# Command ロール（インターフェース）
package Todo::Command {
    use Moo::Role;
    requires 'execute';
}

# ConcreteCommand: AddCommand
package Todo::Command::Add {
    use Moo;
    with 'Todo::Command';
    
    has repository => (is => 'ro', required => 1);
    has title      => (is => 'ro', required => 1);
    
    sub execute {
        my $self = shift;
        $self->repository->add($self->title);
        print "タスクを追加しました: " . $self->title . "\n";
    }
}

# Invoker
package Todo::CLI::Dispatcher {
    use Moo;
    
    has command => (is => 'rw');
    
    sub dispatch {
        my $self = shift;
        $self->command->execute if $self->command;
    }
}
```

**信頼度**: 高

### 1.4 Strategyパターンとの違い

**要点**:

| 観点 | Command パターン | Strategy パターン |
|-----|-----------------|------------------|
| **目的** | リクエストをオブジェクトとしてカプセル化 | アルゴリズムをカプセル化 |
| **焦点** | 「何をするか」（アクション） | 「どうやってするか」（方法） |
| **典型的な機能** | Undo/Redo、キューイング、ログ | アルゴリズムの動的切り替え |
| **典型例** | CLIコマンド、GUIボタンのアクション | ソートアルゴリズム、保存形式の切り替え |

**根拠**:

- 前シリーズ「Mooを使ってディスパッチャーを作ってみよう」ではStrategyパターンを扱った
- 今回のシリーズでは、Commandパターンを扱うことで差別化と学習の連続性を確保

**出典**:

- GeeksforGeeks: Difference between Strategy pattern and Command pattern - https://www.geeksforgeeks.org/system-design/difference-between-strategy-pattern-and-command-pattern/

**信頼度**: 高

---

## 2. Repositoryパターンについて

### 2.1 概要

**要点**:

- Repositoryパターンは、データアクセスを抽象化する構造パターンである
- ビジネスロジックとデータストレージの間に抽象化レイヤーを提供し、疎結合な設計を実現する
- 実装を差し替えることでテスタビリティが向上する（InMemoryRepository → FileRepository → SQLiteRepository）

**根拠**:

- Repositoryパターンはドメイン駆動設計（DDD）において重要なパターンとして知られている
- データストレージの詳細を隠蔽することで、ビジネスロジックのテストが容易になる
- 複数の実装を持つことで、開発環境（InMemory）と本番環境（SQLite）で異なる永続化方法を使用できる

**仮定**:

- Todo CLIアプリでは、最初はInMemoryRepositoryで開発し、後にFileRepository（JSON）やSQLiteRepositoryに移行する流れが教育的に効果的

**出典**:

- GeeksforGeeks: Repository Design Pattern - https://www.geeksforgeeks.org/system-design/repository-design-pattern/
- Microsoft Learn: The Repository Pattern - https://learn.microsoft.com/en-us/previous-versions/msp-n-p/ff649690(v=pandp.10)
- Generalist Programmer: What is Repository Pattern - https://generalistprogrammer.com/glossary/repository-pattern
- HiBit.dev: The Repository Pattern - https://www.hibit.dev/posts/123/the-repository-pattern

**信頼度**: 高

### 2.2 メリット

| メリット | 説明 |
|---------|------|
| **テスタビリティ向上** | InMemoryRepositoryを使うことで、ファイルやDBなしでテスト可能 |
| **疎結合** | ビジネスロジックがデータストレージの実装詳細に依存しない |
| **拡張性** | 新しい永続化方法（Redis、PostgreSQLなど）を追加してもビジネスロジックは変更不要 |
| **一貫性** | データアクセスのルールを一箇所で管理できる |

### 2.3 InMemoryRepository と FileRepository の違い

**要点**:

| 観点 | InMemoryRepository | FileRepository (JSON) |
|-----|-------------------|----------------------|
| **データ保持** | メモリ上（プロセス終了で消失） | ファイルに永続化 |
| **用途** | テスト、開発、プロトタイピング | 軽量な永続化、単一ユーザーアプリ |
| **パフォーマンス** | 高速 | ファイルI/Oによる遅延 |
| **スケーラビリティ** | 低（メモリ制限） | 低（同時書き込み問題） |
| **実装の複雑さ** | 低 | 中（ファイル読み書きの実装が必要） |

### 2.4 Perlでの実装例

```perl
# Repository ロール（インターフェース）
package Todo::Repository {
    use Moo::Role;
    requires qw(add find_by_id find_all update delete);
}

# InMemoryRepository
package Todo::Repository::InMemory {
    use Moo;
    with 'Todo::Repository';
    
    has _storage => (is => 'ro', default => sub { [] });
    has _next_id => (is => 'rw', default => 1);
    
    sub add {
        my ($self, $title) = @_;
        my $todo = {
            id        => $self->_next_id,
            title     => $title,
            completed => 0,
        };
        push @{$self->_storage}, $todo;
        $self->_next_id($self->_next_id + 1);
        return $todo;
    }
    
    sub find_by_id {
        my ($self, $id) = @_;
        my ($todo) = grep { $_->{id} == $id } @{$self->_storage};
        return $todo;
    }
    
    sub find_all {
        my $self = shift;
        return @{$self->_storage};
    }
    
    sub update {
        my ($self, $id, $data) = @_;
        my $todo = $self->find_by_id($id);
        return unless $todo;
        $todo->{$_} = $data->{$_} for keys %$data;
        return $todo;
    }
    
    sub delete {
        my ($self, $id) = @_;
        $self->_storage([grep { $_->{id} != $id } @{$self->_storage}]);
    }
}

# FileRepository (JSON)
package Todo::Repository::File {
    use Moo;
    use JSON::MaybeXS;
    use Path::Tiny;
    with 'Todo::Repository';
    
    has filepath => (is => 'ro', required => 1);
    
    sub _load {
        my $self = shift;
        my $file = path($self->filepath);
        return [] unless $file->exists;
        return decode_json($file->slurp_utf8);
    }
    
    sub _save {
        my ($self, $data) = @_;
        path($self->filepath)->spew_utf8(encode_json($data));
    }
    
    sub add {
        my ($self, $title) = @_;
        my $todos = $self->_load;
        my $max_id = @$todos ? (sort { $b->{id} <=> $a->{id} } @$todos)[0]->{id} : 0;
        my $todo = {
            id        => $max_id + 1,
            title     => $title,
            completed => 0,
        };
        push @$todos, $todo;
        $self->_save($todos);
        return $todo;
    }
    
    # 他のメソッドも同様に実装...
}
```

**信頼度**: 高

---

## 3. Perl CLIアプリケーション開発

### 3.1 Getopt::Long

**要点**:

- Getopt::Longは、Perlの標準モジュールで、コマンドライン引数の解析を行う
- 長いオプション名（`--file`）と短いオプション名（`-f`）をサポート
- オプションの型（文字列、整数、真偽値）を指定可能

**根拠**:

- Perl標準ライブラリに含まれており、追加のインストールが不要
- 多くのPerl CLIアプリケーションで使用されている実績がある

**出典**:

- Perldoc: Getopt::Long - https://perldoc.perl.org/Getopt::Long
- Perl Maven: Advanced usage of Getopt::Long - https://perlmaven.com/advanced-usage-of-getopt-long-accepting-command-line-arguments
- Stack Overflow: What are the best-practices for implementing a CLI tool in Perl? - https://stackoverflow.com/questions/1183876/what-are-the-best-practices-for-implementing-a-cli-tool-in-perl

**信頼度**: 高

### 3.2 基本的な使い方

```perl
use Getopt::Long;

my $help;
my $file = "todos.json";
my $verbose;

GetOptions(
    'help|h'    => \$help,
    'file|f=s'  => \$file,
    'verbose|v' => \$verbose,
) or die "Error in command line arguments\n";

if ($help) {
    print "Usage: todo.pl [options] <command> [args]\n";
    print "  -h, --help     Show this help message\n";
    print "  -f, --file     Specify todo file (default: todos.json)\n";
    print "  -v, --verbose  Enable verbose output\n";
    exit 0;
}
```

### 3.3 App::Cmd

**要点**:

- App::Cmdは、複数のサブコマンドを持つCLIアプリケーションを構築するためのフレームワーク
- gitやsvnのようなサブコマンド構造（`todo add`, `todo list`）を簡単に実装できる
- 各コマンドが独立したモジュールとして実装され、メンテナンス性が高い

**根拠**:

- 大規模なCLIアプリケーションでの使用実績がある
- コマンドごとにオプション解析が自動化される

**出典**:

- CPAN: App::Cmd - https://metacpan.org/pod/App::Cmd

**信頼度**: 高

### 3.4 CLIアプリケーション設計のベストプラクティス

| プラクティス | 説明 |
|-------------|------|
| **ヘルプメッセージ** | `--help`または`-h`オプションで使い方を表示 |
| **エラーハンドリング** | エラーはSTDERRに出力、終了コードは非ゼロ |
| **デフォルト値** | オプションにはデフォルト値を設定し、ヘルプに表示 |
| **dry-runオプション** | 副作用のある操作には確認オプションを提供 |
| **入出力** | ファイル指定オプションを提供し、パイプ処理をサポート |

---

## 4. JSON / SQLiteでのデータ永続化

### 4.1 PerlでのJSON処理

**要点**:

- JSON::MaybeXSは、利用可能な最速のJSONモジュールを自動選択するラッパー
- Cpanel::JSON::XS（XS実装）が利用可能ならそれを使用し、なければJSON::PP（Pure Perl）にフォールバック
- `encode_json`と`decode_json`関数で簡単にシリアライズ/デシリアライズ可能

**根拠**:

- JSON::MaybeXSはモダンなPerlプロジェクトでの標準的な選択肢
- パフォーマンスとポータビリティのバランスが良い

**出典**:

- MetaCPAN: JSON::MaybeXS - https://metacpan.org/pod/JSON::MaybeXS
- Perl Maven: JSON in Perl - https://perlmaven.com/json
- Cpanel::JSON::XS - https://perl11.github.io/cperl/lib/Cpanel/JSON/XS.html

**信頼度**: 高

### 4.2 JSON読み書きの実装例

```perl
use JSON::MaybeXS;
use Path::Tiny;

# 書き込み
my $todos = [
    { id => 1, title => '買い物', completed => 0 },
    { id => 2, title => '掃除', completed => 1 },
];
path('todos.json')->spew_utf8(encode_json($todos));

# 読み込み
my $loaded = decode_json(path('todos.json')->slurp_utf8);
```

### 4.3 PerlでのSQLite処理

**要点**:

- DBIはPerlのデータベースインターフェース標準
- DBD::SQLiteはSQLiteデータベースへのドライバ
- SQLiteはファイルベースで軽量、サーバー不要

**根拠**:

- SQLiteはシングルユーザーのCLIアプリケーションに最適
- データの整合性やクエリ機能が必要な場合にJSONより優れている

**出典**:

- MetaCPAN: DBI - https://metacpan.org/pod/DBI
- MetaCPAN: DBD::SQLite - https://metacpan.org/pod/DBD::SQLite
- Tutorialspoint: SQLite Perl - https://www.tutorialspoint.com/sqlite/sqlite_perl.htm
- Xmodulo: How to access SQLite database in Perl - https://www.xmodulo.com/access-sqlite-database-perl.html

**信頼度**: 高

### 4.4 SQLite CRUD操作の実装例

```perl
use DBI;

# 接続
my $dbh = DBI->connect("dbi:SQLite:dbname=todos.db", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

# テーブル作成
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER DEFAULT 0
    )
});

# 追加（Create）
my $sth = $dbh->prepare("INSERT INTO todos (title) VALUES (?)");
$sth->execute('買い物');

# 読み取り（Read）
$sth = $dbh->prepare("SELECT * FROM todos");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    print "$row->{id}: $row->{title} [" . ($row->{completed} ? 'X' : ' ') . "]\n";
}

# 更新（Update）
$sth = $dbh->prepare("UPDATE todos SET completed = 1 WHERE id = ?");
$sth->execute(1);

# 削除（Delete）
$sth = $dbh->prepare("DELETE FROM todos WHERE id = ?");
$sth->execute(1);

$dbh->disconnect;
```

### 4.5 JSON vs SQLite 比較

| 観点 | JSON (ファイル) | SQLite |
|-----|----------------|--------|
| **セットアップ** | 簡単（追加モジュール少ない） | やや複雑（DBD::SQLiteが必要） |
| **クエリ機能** | なし（全データを読み込んでフィルタ） | SQLで柔軟なクエリ可能 |
| **パフォーマンス** | 小規模データなら十分 | 大規模データに強い |
| **データ整合性** | アプリ側で管理 | ACID特性をサポート |
| **可読性** | JSONファイルを直接編集可能 | 専用ツールが必要 |
| **学習コスト** | 低い | SQLの知識が必要 |

---

## 5. 競合記事の分析

### 5.1 GitHub上の類似プロジェクト

| プロジェクト | 特徴 | 差別化ポイント |
|-------------|------|---------------|
| mnestorov/todo-list | Storableで永続化、優先度・期限付き | デザインパターンを明示的に教えていない |
| Sumit4codes/TODO-in-perl | シンプルな番号付きリスト | オブジェクト指向設計なし |
| TotemaT/todo-cli | ミニマル実装 | 教育的な説明がない |

**出典**:

- GitHub: mnestorov/todo-list - https://github.com/mnestorov/todo-list
- GitHub: Sumit4codes/TODO-in-perl - https://github.com/Sumit4codes/TODO-in-perl
- GitHub: TotemaT/todo-cli - https://github.com/TotemaT/todo-cli

**信頼度**: 中（オープンソースプロジェクト）

### 5.2 本シリーズの差別化ポイント

1. **デザインパターンの明示的な導入**: CommandパターンとRepositoryパターンを段階的に導入
2. **Mooを使用したモダンなPerl**: 前シリーズの知識を活かしたOOP設計
3. **テスト駆動開発（TDD）**: Test2を使用したテスト手法の紹介
4. **段階的な永続化**: InMemory → JSON → SQLiteへの移行を体験
5. **日本語での詳細な解説**: Perl入学式卒業者向けの丁寧な説明

---

## 6. 内部リンク調査

### 6.1 関連記事一覧

以下は、本シリーズ記事から内部リンクとして参照可能な関連記事です。

#### 6.1.1 Mooシリーズ（前提知識として必須）

| 記事タイトル | 内部リンク | 関連度 |
|-------------|-----------|--------|
| 第1回-Mooで覚えるオブジェクト指向プログラミング | `/2021/10/31/191008/` | 必須 |
| 第2回-データとロジックをまとめよう | `/2025/12/30/163810/` | 必須 |
| 第3回-同じものを何度も作れるように | `/2025/12/30/163811/` | 必須 |
| 第4回-勝手に書き換えられないようにする | `/2025/12/30/163812/` | 必須 |
| 第7回-関連するデータを別のクラスに | `/2025/12/30/163815/` | 高 |
| 第11回-「持っている」ものに仕事を任せる | `/2025/12/30/163819/` | 高 |
| 第12回-型チェックでバグを未然に防ぐ | `/2025/12/30/163820/` | 高 |

#### 6.1.2 デザインパターン関連

| 記事タイトル | 内部リンク | 関連度 |
|-------------|-----------|--------|
| 第12回-これがデザインパターンだ！ - Mooを使ってディスパッチャーを作ってみよう | `/2025/12/30/164012/` | 高（Strategyパターン解説） |

#### 6.1.3 Perl開発環境・ツール

| 記事タイトル | 内部リンク | 関連度 |
|-------------|-----------|--------|
| Test2フレームワーク入門 | `/2025/12/07/000000/` | 高（テスト実装） |
| Carton/cpanfile - モダンなPerl依存関係管理 | `/2025/12/10/000000/` | 中（開発環境） |
| Mojolicious入門 | `/2025/12/04/000000/` | 低（フレームワーク参考） |

#### 6.1.4 JSON-RPC / 値オブジェクト関連

| 記事タイトル | 内部リンク | 関連度 |
|-------------|-----------|--------|
| JSON-RPC Request/Response実装 - 複合値オブジェクト設計【Perl×TDD】 | `/2025/12/25/234500/` | 中（TDD、Type::Tiny） |

---

## 7. 技術的正確性を担保するためのリソースリスト

### 7.1 公式ドキュメント（CPAN）

| モジュール | URL | 用途 |
|-----------|-----|------|
| Moo | https://metacpan.org/pod/Moo | オブジェクト指向フレームワーク |
| Moo::Role | https://metacpan.org/pod/Moo::Role | ロール（インターフェース）定義 |
| Types::Standard | https://metacpan.org/pod/Types::Standard | 型制約 |
| Getopt::Long | https://perldoc.perl.org/Getopt::Long | コマンドライン引数解析 |
| App::Cmd | https://metacpan.org/pod/App::Cmd | CLIフレームワーク |
| JSON::MaybeXS | https://metacpan.org/pod/JSON::MaybeXS | JSON処理 |
| DBI | https://metacpan.org/pod/DBI | データベースインターフェース |
| DBD::SQLite | https://metacpan.org/pod/DBD::SQLite | SQLiteドライバ |
| Path::Tiny | https://metacpan.org/pod/Path::Tiny | ファイル操作 |
| Test2::V0 | https://metacpan.org/pod/Test2::V0 | テストフレームワーク |

### 7.2 書籍

| 書籍名 | 著者 | ISBN | 用途 |
|-------|------|------|------|
| Design Patterns: Elements of Reusable Object-Oriented Software | GoF | 978-0201633610 | デザインパターン原典 |
| Head First Design Patterns (2nd Edition) | Eric Freeman, Elisabeth Robson | 978-1492078005 | 初心者向けデザインパターン |
| Modern Perl (4th Edition) | chromatic | 978-1680500882 | モダンPerl開発 |
| Perl Best Practices | Damian Conway | 978-0596001735 | Perlベストプラクティス |

### 7.3 オンラインリソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| Refactoring Guru - Command | https://refactoring.guru/design-patterns/command | 視覚的な図解、多言語コード例 |
| GeeksforGeeks - Repository Pattern | https://www.geeksforgeeks.org/system-design/repository-design-pattern/ | 網羅的な解説 |
| Perl Maven | https://perlmaven.com/ | 実践的なPerlチュートリアル |
| PerlMonks | https://www.perlmonks.org/ | Perlコミュニティ |

---

## 8. 調査結果のサマリー

### 8.1 主要な発見

1. **Commandパターン**: Todo CLIの各操作（add, list, done, delete）をコマンドオブジェクトとして実装することで、Undo/Redo機能の追加が容易になる
2. **Repositoryパターン**: InMemory → JSON → SQLiteへの段階的移行により、永続化の抽象化を体験的に学べる
3. **Perl CLIツール**: Getopt::Longは標準的で学習コストが低い。複雑なアプリにはApp::Cmdを検討
4. **JSON vs SQLite**: 学習目的では両方を扱い、用途に応じた使い分けを教える
5. **差別化**: 既存のPerl TodoアプリはデザインパターンやOOP設計を明示的に教えていない

### 8.2 シリーズ構成の提案

1. **第1回**: Todo CLIアプリの基本構造と設計方針
2. **第2回**: InMemoryRepositoryの実装とCRUD操作
3. **第3回**: Commandパターンの導入
4. **第4回**: JSONファイルへの永続化（FileRepository）
5. **第5回**: SQLiteへの移行（SQLiteRepository）
6. **第6回**: CLIインターフェースの完成とGetopt::Long
7. **第7回**: テストの追加とリファクタリング

### 8.3 前提知識の確認

読者は以下の概念を習得済みであることを前提とする：

- Mooの基本（has, sub, new, is, required, default）
- カプセル化
- クラス連携
- 継承（extends）
- オーバーライド
- ロール（Moo::Role, with）
- 委譲（handles）
- 型制約（isa, Types::Standard）

---

**調査完了日**: 2026年1月1日  
**調査者**: AI Copilot (専門: ソフトウェアエンジニアリング、Perl開発)
