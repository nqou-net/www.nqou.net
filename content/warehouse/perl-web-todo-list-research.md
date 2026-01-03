---
title: "調査ドキュメント: TODOリスト（Web版）をPerlで作成するシリーズ記事"
description: "シリーズ記事「TODOリスト（Web版）を作ってみよう」の連載構造案を作成するための調査結果"
date: 2025-12-31
draft: true
tags:
  - perl
  - mojolicious
  - moo
  - json
  - dbi
  - sqlite
  - crud
  - research
---

## 調査概要

### 調査目的

シリーズ記事「TODOリスト（Web版）を作ってみよう」の連載構造案を作成するための情報収集と調査を行う。

### 想定読者

- Perl入学式卒業程度
- 「Mooで覚えるオブジェクト指向プログラミング（全12回）」を読了した方
- オブジェクト指向プログラミングの基礎を理解している

### 学習内容

- CRUD（生成・読み取り・更新・削除）
- ファイル入出力
- JSONでの保存
- 基本的なデータの扱い
- テキストファイル保存→JSON形式→データベース（SQLite）へのステップアップ

### 調査実施日

2025-12-31

---

## 1. Webアプリの基礎

### 1.1 Mojoliciousの概要と利点

**要点**:

Mojoliciousは「The Web in a Box!」というキャッチフレーズの通り、Webアプリケーション開発に必要なすべてが1つに詰まったPerlのモダンなWebフレームワークである。

**主な利点**:

1. **依存関係ゼロ**: コアPerl以外の依存モジュールがない
2. **フルスタック**: HTTPクライアント、WebSocketサポート、テンプレートエンジン、JSONパーサーなど全て内蔵
3. **非同期I/O**: イベントループを内蔵し、高性能な非同期処理が可能
4. **開発が楽しい**: 美しいAPIと優れたドキュメント
5. **RESTful**: RESTful APIの開発に最適化

**根拠**:

- 内部記事（`/2025/12/04/000000/`）で詳細に解説されている
- 公式ドキュメントで明記されている特徴

**出典**:

- 内部記事: /2025/12/04/000000/ (Mojolicious入門)
- 公式サイト: https://mojolicious.org/
- 公式ドキュメント: https://docs.mojolicious.org/
- MetaCPAN: https://metacpan.org/pod/Mojolicious

**信頼度**: 高（公式ドキュメントおよび内部記事に基づく）

---

### 1.2 Mojolicious::Liteとフルアプリの違い

**要点**:

Mojoliciousには2つのモードがあり、開発フェーズに応じて使い分ける。

| Mojolicious::Lite | フルMojolicious |
|-------------------|-----------------|
| 単一ファイルで完結 | プロジェクト構造に分離 |
| プロトタイピングに最適 | スケーラブルなアーキテクチャ |
| 最小限のボイラープレート | 明確なMVC分離 |
| 学習・デモ向け | チーム開発・本番向け |
| 上位への移行が容易 | 拡張性を重視した設計 |

**根拠**:

- Mojolicious::Liteは軽量なDSL（ドメイン固有言語）で、フルMojoliciousの薄いラッパー
- 同じ技術基盤を使用しているため、成長に応じて段階的に移行可能
- 公式の「Growing Guide」で移行パスが詳細に説明されている

**仮定**:

- 本シリーズではMojolicious::Liteから開始し、連載の後半でフルアプリへの移行を扱う可能性がある

**出典**:

- Mojolicious::Lite公式ドキュメント: https://docs.mojolicious.org/Mojolicious/Lite
- Growing Guide: https://docs.mojolicious.org/Mojolicious/Guides/Growing
- mojolicious.io解説記事: https://mojolicious.io/blog/2017/12/04/day-4-dont-fear-the-full-app/
- blogs.perl.org解説: https://blogs.perl.org/users/tempire/2012/02/mojolicious-full-and-lite-apps---understanding-the-difference.html

**信頼度**: 高

---

### 1.3 ルーティングの基本

**要点**:

Mojoliciousのルーティングは非常に柔軟で、様々なHTTPメソッドとURLパターンに対応できる。

**基本パターン**:

```perl
# GETリクエスト
get '/' => sub ($c) { ... };

# POSTリクエスト
post '/submit' => sub ($c) { ... };

# パラメータ付きルート
get '/task/:id' => sub ($c) {
    my $id = $c->param('id');
    ...
};

# HTTPメソッドに対応するルーティング
# GET    /tasks     -> 一覧表示（Read）
# POST   /tasks     -> 新規作成（Create）
# GET    /tasks/:id -> 詳細表示（Read）
# PUT    /tasks/:id -> 更新（Update）
# DELETE /tasks/:id -> 削除（Delete）
```

**プレースホルダーの種類**:

- `:name` - 標準プレースホルダー（`/`以外の任意の文字列）
- `*filepath` - ワイルドカード（`/`を含む任意の文字列）
- `[name => qr/.../]` - 正規表現による制約

**根拠**:

- 内部記事でルーティングの詳細が解説済み
- RESTful APIの標準的なパターン

**出典**:

- 内部記事: /2025/12/04/000000/ (ルーティングセクション)
- 公式チュートリアル: https://docs.mojolicious.org/Mojolicious/Guides/Tutorial

**信頼度**: 高

---

## 2. データ永続化の段階的学習

### 2.1 テキストファイルでのデータ保存方法

**要点**:

Perlでのファイル入出力は`open`関数を使用する。UTF-8エンコーディングへの対応が重要。

**基本パターン**:

```perl
# 読み込み（UTF-8対応）
open my $fh, '<:encoding(UTF-8)', $filename or die "Cannot open: $!";
my @lines = <$fh>;
close $fh;

# 書き込み（UTF-8対応）
open my $fh, '>:encoding(UTF-8)', $filename or die "Cannot open: $!";
print $fh "データ\n";
close $fh;
```

**モダンなアプローチ: Path::Tiny**:

```perl
use Path::Tiny;

# 読み込み
my $content = path('file.txt')->slurp_utf8;

# 書き込み
path('file.txt')->spew_utf8($content);
```

**根拠**:

- 3引数形式の`open`がセキュリティ上推奨される
- 日本語を扱う場合は必ず文字コード指定（UTF-8）が必要
- Path::Tinyは内部記事（CPAN20選）で紹介済み

**出典**:

- 内部記事: /2025/12/03/041603/ (CPAN20選 - Path::Tiny)
- perldoc: https://perldoc.perl.org/functions/open
- Path::Tiny: https://metacpan.org/pod/Path::Tiny

**信頼度**: 高

---

### 2.2 JSON形式でのデータ保存（JSON.pmモジュール）

**要点**:

JSON（JavaScript Object Notation）はデータ交換フォーマットとして広く使われる。Perlでは`JSON`モジュールや`Mojo::JSON`で扱える。

**基本パターン**:

```perl
use JSON;
use Path::Tiny;

# データをJSONに変換して保存
my $tasks = [
    { id => 1, title => 'Learn Perl', done => 0 },
    { id => 2, title => 'Build App', done => 0 },
];
my $json_text = encode_json($tasks);
path('tasks.json')->spew_utf8($json_text);

# JSONからデータを読み込み
my $json_text = path('tasks.json')->slurp_utf8;
my $tasks = decode_json($json_text);
```

**Mojoliciousを使う場合**:

```perl
use Mojo::JSON qw(encode_json decode_json);

# MojoliciousにはJSONサポートが組み込まれている
my $json = encode_json({ title => 'Task' });
my $data = decode_json($json);
```

**根拠**:

- JSONはWebアプリケーションでの標準的なデータ交換形式
- テキストファイルより構造化されたデータを扱いやすい
- データベースへの移行前の中間ステップとして最適

**出典**:

- MetaCPAN JSON: https://metacpan.org/pod/JSON
- MetaCPAN Mojo::JSON: https://metacpan.org/pod/Mojo::JSON
- 内部記事: /2025/12/04/000000/ (JSON APIセクション)

**信頼度**: 高

---

### 2.3 SQLiteへの移行（DBI）

**要点**:

SQLiteはファイルベースで軽量なデータベース。学習・小規模プロジェクトに最適で、サーバー設定不要で使い始められる。

**DBI + SQLiteの基本**:

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

**重要なポイント**:

- **プレースホルダ使用が必須**: SQLインジェクション対策
- **RaiseError => 1**: エラー時に例外を投げる
- **AutoCommit**: トランザクション制御

**根拠**:

- 内部記事「Perlでのデータベース操作 — DBI / DBIx::Class 入門」で詳しく解説されている
- SQLiteはインストールが容易で、初学者に最適

**出典**:

- 内部記事: /2025/12/13/000000/ (DBI/DBIx::Class入門)
- MetaCPAN DBI: https://metacpan.org/pod/DBI
- MetaCPAN DBD::SQLite: https://metacpan.org/pod/DBD::SQLite

**信頼度**: 高

---

## 3. CRUDの実装

### 3.1 各操作の標準的な実装パターン

**要点**:

CRUDは「Create（生成）」「Read（読み取り）」「Update（更新）」「Delete（削除）」の頭文字で、データ操作の基本4操作を表す。

#### Create（タスク追加）

```perl
my $sth = $dbh->prepare('INSERT INTO tasks (title) VALUES (?)');
$sth->execute($title);
my $id = $dbh->last_insert_id(undef, undef, 'tasks', 'id');
```

#### Read（タスク一覧・詳細）

```perl
# 全件取得
my $sth = $dbh->prepare('SELECT * FROM tasks ORDER BY created_at DESC');
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    print "[$row->{id}] $row->{title}\n";
}

# 1件取得
my $sth = $dbh->prepare('SELECT * FROM tasks WHERE id = ?');
$sth->execute($id);
my $task = $sth->fetchrow_hashref;
```

#### Update（タスク更新・完了）

```perl
my $sth = $dbh->prepare('UPDATE tasks SET done = 1 WHERE id = ?');
$sth->execute($id);
```

#### Delete（タスク削除）

```perl
my $sth = $dbh->prepare('DELETE FROM tasks WHERE id = ?');
$sth->execute($id);
```

**根拠**:

- DBIの標準的な使用パターン
- 内部記事で詳細に解説済み

**出典**:

- 内部記事: /2025/12/13/000000/ (DBI/DBIx::Class入門)
- Joel Bergerの解説記事: https://blogs.perl.org/users/joel_berger/2012/10/a-simple-mojoliciousdbi-example.html

**信頼度**: 高

---

### 3.2 HTTPメソッドとの対応

**要点**:

RESTful APIでは、CRUDの各操作がHTTPメソッドに対応する。

| CRUD操作 | HTTPメソッド | URLパターン | 説明 |
|----------|-------------|-------------|------|
| Create | POST | /tasks | 新規タスク作成 |
| Read (一覧) | GET | /tasks | タスク一覧取得 |
| Read (詳細) | GET | /tasks/:id | 特定タスク取得 |
| Update | PUT/PATCH | /tasks/:id | タスク更新 |
| Delete | DELETE | /tasks/:id | タスク削除 |

**Mojoliciousでの実装**:

```perl
get '/tasks' => sub ($c) { ... };           # 一覧
get '/tasks/:id' => sub ($c) { ... };       # 詳細
post '/tasks' => sub ($c) { ... };          # 作成
put '/tasks/:id' => sub ($c) { ... };       # 更新
del '/tasks/:id' => sub ($c) { ... };       # 削除
```

**根拠**:

- RESTful APIの標準的な設計パターン
- 内部記事のJSON APIセクションで解説済み

**出典**:

- 内部記事: /2025/12/04/000000/ (JSON APIセクション)
- RESTful API設計の一般的なベストプラクティス

**信頼度**: 高

---

### 3.3 フォームからのデータ受け取り

**要点**:

MojoliciousではHTMLフォームからのデータを`$c->param()`で受け取れる。

**基本パターン**:

```perl
post '/tasks' => sub ($c) {
    my $title = $c->param('title');
    # バリデーション
    return $c->render(text => 'タイトルを入力してください', status => 400)
        unless $title;
    # タスク作成処理
    ...
};
```

**HTMLフォーム**:

```html
<form method="post" action="/tasks">
    <input type="text" name="title" placeholder="タスク名">
    <button type="submit">追加</button>
</form>
```

**根拠**:

- Mojoliciousの標準的なフォーム処理方法
- 内部記事で解説済み

**出典**:

- 内部記事: /2025/12/04/000000/
- 公式チュートリアル: https://docs.mojolicious.org/Mojolicious/Guides/Tutorial

**信頼度**: 高

---

## 4. デザインパターン

### 4.1 MVCパターンの自然な適用

**要点**:

MVCは「Model（モデル）」「View（ビュー）」「Controller（コントローラ）」の頭文字で、責務を分離する設計パターン。

| 要素 | 役割 | Mojoliciousでの実装 |
|------|------|---------------------|
| Model | データと業務ロジック | 独立したPerlモジュール |
| View | 表示・出力 | テンプレート（.ep） |
| Controller | 入力処理・制御 | アクション（ルート定義） |

**処理の流れ**:

```
クライアントリクエスト → Controller → Model → Controller → View → レスポンス
```

**Mojoliciousでの例**:

```perl
# Controller（ルート定義）
get '/tasks' => sub ($c) {
    my $tasks = $c->model('Task')->all();  # Model呼び出し
    $c->render(template => 'tasks/index', tasks => $tasks);  # View呼び出し
};
```

**根拠**:

- 公式ドキュメントのGrowing Guideで詳細に説明
- 大規模アプリケーション開発の標準的なパターン

**仮定**:

- 連載の後半で自然にMVCパターンを導入し、責務分離の重要性を理解させる

**出典**:

- Growing Guide: https://docs.mojolicious.org/Mojolicious/Guides/Growing
- 公式チュートリアル: https://docs.mojolicious.org/Mojolicious/Guides/Tutorial

**信頼度**: 高

---

### 4.2 テンプレートによるビューの分離

**要点**:

MojoliciousはEP（Embedded Perl）テンプレートをサポートし、HTMLとロジックを分離できる。

**インラインテンプレート**:

```perl
get '/tasks' => sub ($c) {
    $c->render(template => 'tasks');
};

__DATA__

@@ tasks.html.ep
<!DOCTYPE html>
<html>
<head><title>TODOリスト</title></head>
<body>
    <h1>タスク一覧</h1>
    <ul>
    % for my $task (@$tasks) {
        <li><%= $task->{title} %></li>
    % }
    </ul>
</body>
</html>
```

**テンプレートの記法**:

- `<%= ... %>`: Perlコードの評価結果を出力（HTMLエスケープあり）
- `<%== ... %>`: HTMLエスケープなしで出力
- `% ...`: 行頭の`%`でPerlコードを記述

**根拠**:

- 内部記事で詳細に解説済み
- フレームワークの標準機能

**出典**:

- 内部記事: /2025/12/04/000000/ (テンプレートセクション)
- 公式ドキュメント: https://docs.mojolicious.org/Mojo/Template

**信頼度**: 高

---

### 4.3 モデルクラスの設計（Mooとの組み合わせ）

**要点**:

MooとMojoliciousを組み合わせることで、データ層（Model）をオブジェクト指向で設計できる。

**Taskモデルの例**:

```perl
package Task;
use Moo;
use DBI;
use namespace::clean;

has dbh => (is => 'ro', required => 1);
has id => (is => 'rw');
has title => (is => 'rw');
has done => (is => 'rw', default => 0);

sub save {
    my $self = shift;
    if ($self->id) {
        # 更新
        $self->dbh->do(
            'UPDATE tasks SET title = ?, done = ? WHERE id = ?',
            undef, $self->title, $self->done, $self->id
        );
    } else {
        # 新規作成
        $self->dbh->do(
            'INSERT INTO tasks (title, done) VALUES (?, ?)',
            undef, $self->title, $self->done
        );
        $self->id($self->dbh->last_insert_id('', '', 'tasks', ''));
    }
    return $self->id;
}

1;
```

**根拠**:

- Mooシリーズ（全12回）の知識を活用
- ドメインロジックをモデルクラスにカプセル化するのはOOPのベストプラクティス

**仮定**:

- 読者はMooの基本（has、属性、メソッド）を既に理解している

**出典**:

- 内部記事: /2021/10/31/191008/ (Mooで覚えるオブジェクト指向第1回)
- Moo公式ドキュメント: https://metacpan.org/pod/Moo
- Perl Maven OOP with Moo: https://perlmaven.com/oop-with-moo

**信頼度**: 高

---

## 5. 競合記事の分析

### 5.1 日本語の競合・参考記事

| サイト/記事 | URL | 特徴 | 差別化ポイント |
|-------------|-----|------|---------------|
| **Mojoliciousドキュメント日本語訳** | https://mojodoc.perlzemi.com/ | 公式ドキュメントの翻訳、網羅的 | 初心者向けの段階的解説 |
| **Perlゼミ** | https://perlzemi.com/ | 基礎から丁寧、初心者向け | TODOアプリという実践的題材 |
| **ものづくりのブログ** | https://a1026302.hatenablog.com/entry/2025/04/05/093755 | Mojoliciousの導入記事 | 連載形式での学習パス |
| **perldoc.jp** | https://perldoc.jp/pod/Mojolicious::Guides::Tutorial | 公式チュートリアル翻訳 | Mooとの統合、OOP設計 |

### 5.2 英語の競合・参考記事

| サイト/記事 | URL | 特徴 | 差別化ポイント |
|-------------|-----|------|---------------|
| **Mojolicious公式チュートリアル** | https://docs.mojolicious.org/Mojolicious/Guides/Tutorial | 公式、網羅的 | 日本語での解説 |
| **Joel Berger - Mojolicious/DBI Example** | https://blogs.perl.org/users/joel_berger/2012/10/a-simple-mojoliciousdbi-example.html | シンプルなDBI統合例 | 段階的なデータ永続化学習 |
| **Perl Maven - Mojolicious** | https://perlmaven.com/mojolicious | スクリーンキャスト付き | 1記事1概念の原則 |
| **mojolicious.io** | https://mojolicious.io/ | 実践的なTipsが多い | Mooシリーズとの連携 |

### 5.3 本シリーズの差別化ポイント

1. **Perl入学式+Mooシリーズ卒業生に最適化**: 既知事項を前提とした適切な難易度
2. **段階的なデータ永続化**: テキストファイル→JSON→SQLiteへのステップアップ
3. **1記事1概念の原則**: 消化しやすい分量で着実に学習
4. **各回コード例2つまで**: 集中できる内容
5. **Mooとの統合**: オブジェクト指向設計の実践
6. **デザインパターンの自然な習得**: MVCパターンを意識せずに身につける

---

## 6. 内部リンク候補（関連記事）

### 6.1 Mojolicious関連

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/post/2025/12/04/000000.md | /2025/12/04/000000/ | Mojolicious入門 — Mojolicious::Liteで始めるPerlのWeb開発 | **最高** |

### 6.2 Moo / オブジェクト指向関連

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/post/2021/10/31/191008.md | /2021/10/31/191008/ | 第1回-Mooで覚えるオブジェクト指向プログラミング | **最高** |
| /content/post/2016/02/21/150920.md | /2016/02/21/150920/ | よなべPerlでMooについて喋ってきました | 高 |
| /content/post/2025/12/19/234500.md | /2025/12/19/234500/ | 値オブジェクト(Value Object)入門 - Mooで実装 | 高 |

### 6.3 DBI / SQLite関連

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/post/2025/12/13/000000.md | /2025/12/13/000000/ | Perlでのデータベース操作 — DBI / DBIx::Class 入門 | **最高** |

### 6.4 JSON関連

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/post/2025/12/03/041603.md | /2025/12/03/041603/ | CPANとは — 実務で役立つCPANモジュール20選 | 高 |
| /content/post/2025/12/14/000000.md | /2025/12/14/000000/ | Try::Tiny - 例外処理をスマートに | 中 |

### 6.5 Perl入学式関連

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/post/2016/02/02/084059.md | /2016/02/02/084059/ | Perl入学式（Webアプリ編）で講師をしてきました | 中 |
| /content/post/2015/03/03/100703.md | /2015/03/03/100703/ | Perl入学式で講師役をしてきました | 中 |

### 6.6 CLI版TODOリスト関連（参考）

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|--------|
| /content/warehouse/perl-cli-todo-list-research.md | - | CLI版TODOリスト調査ドキュメント | 参考 |

---

## 7. 技術的正確性を担保するための情報源リスト

### 7.1 公式ドキュメント（最優先）

| リソース | URL | 用途 |
|---------|-----|------|
| Mojolicious公式サイト | https://mojolicious.org/ | フレームワーク概要 |
| Mojolicious::Guides | https://docs.mojolicious.org/ | 公式ガイド全般 |
| Mojolicious::Guides::Tutorial | https://docs.mojolicious.org/Mojolicious/Guides/Tutorial | チュートリアル |
| Mojolicious::Guides::Growing | https://docs.mojolicious.org/Mojolicious/Guides/Growing | アプリ成長ガイド |
| MetaCPAN DBI | https://metacpan.org/pod/DBI | DBI APIリファレンス |
| MetaCPAN DBD::SQLite | https://metacpan.org/pod/DBD::SQLite | SQLite固有の機能 |
| MetaCPAN Moo | https://metacpan.org/pod/Moo | Moo公式ドキュメント |
| MetaCPAN JSON | https://metacpan.org/pod/JSON | JSON処理 |

### 7.2 書籍（推奨）

| 書籍名 | ASIN/ISBN | 用途 |
|--------|-----------|------|
| 初めてのPerl 第7版 | B07DP7W5KS | Perl基礎（ラクダ本） |
| 続・初めてのPerl 改訂第2版 | B00XWE9RBK | より実践的なOOP |
| モダンPerl入門 | B00M0RM3EG | モダンなPerlプラクティス |

### 7.3 本ブログ内の関連記事

| 記事 | 内部リンク | 参照目的 |
|------|-----------|---------|
| Mojolicious入門 | /2025/12/04/000000/ | Webフレームワークの基礎 |
| DBI/DBIx::Class入門 | /2025/12/13/000000/ | データベース操作 |
| Mooで覚えるOOP第1回 | /2021/10/31/191008/ | オブジェクト指向の基礎 |
| CPAN20選 | /2025/12/03/041603/ | モジュール選定の参考 |

---

## 8. 連載構造案への提言

### 8.1 推奨する連載の流れ

連載は大きく3つのフェーズに分けることを推奨する。

**フェーズ1: Webアプリの基礎（第1回〜第4回）**:

- Mojolicious::Liteの導入
- ルーティングとテンプレートの基本
- HTMLフォームからのデータ受け取り
- メモリ上でのCRUD操作

**フェーズ2: データ永続化（第5回〜第8回）**:

- テキストファイルへの保存
- JSON形式での保存
- SQLiteへの移行
- CRUD操作のDB版実装

**フェーズ3: 設計の改善（第9回〜第12回）**:

- モデルクラスの導入（Mooとの統合）
- MVCパターンへの移行
- エラーハンドリング
- まとめと発展（フルアプリへの成長）

### 8.2 1記事1概念の原則に基づく分割案

| 回 | 新しい概念 | 内容 |
|----|-----------|------|
| 第1回 | Mojolicious::Lite導入 | 最小限のWebアプリ作成 |
| 第2回 | ルーティング | GET/POSTルートの定義 |
| 第3回 | テンプレート | EPテンプレートでHTML生成 |
| 第4回 | フォーム処理 | データ受け取りとバリデーション |
| 第5回 | ファイル書き込み | タスクをファイルに保存 |
| 第6回 | ファイル読み込み | 保存したタスクを復元 |
| 第7回 | JSON保存 | 構造化データとしてJSON形式で保存 |
| 第8回 | DBI接続 | SQLiteへの接続と初期化 |
| 第9回 | DB版CRUD | データベースでのCRUD操作 |
| 第10回 | モデルクラス | MooでTaskクラスを作成 |
| 第11回 | 責務分離 | MVCパターンの導入 |
| 第12回 | まとめ | 全体の振り返りと次のステップ |

### 8.3 各回の制約確認

- 毎回コード例は2つまで ✓
- 新しい概念は1記事あたり1つまで ✓
- ゆっくりと少しずつ進める ✓
- Mooシリーズの知識を活用 ✓

---

## 9. 調査結論

### 9.1 調査により判明した事項

1. **Mojoliciousは最適な選択**: 依存関係ゼロ、フルスタック、ドキュメント充実
2. **段階的なデータ永続化が効果的**: ファイル→JSON→SQLiteの流れは自然な学習パス
3. **既存の内部記事が豊富**: Mojolicious入門、DBI入門、Mooシリーズなどを活用可能
4. **Mooとの統合が差別化要素**: 他のチュートリアルにはないOOP設計の実践
5. **競合との差別化は「段階的学習」と「1記事1概念」**: 既存リソースは包括的だが分量が多い

### 9.2 リスクと対策

| リスク | 対策 |
|-------|------|
| Webアプリの概念が初めて | 最初の数回で基礎を丁寧に解説 |
| コード例が複雑化 | 各回の最小限のコードのみ掲載 |
| 読者の離脱 | 各回冒頭で前回の復習、章末でまとめ |
| MooとMojoliciousの統合が難しい | 後半に配置し、段階的に導入 |

### 9.3 次のステップ

連載構造案の作成（3案）を `/content/warehouse/perl-web-todo-list-structure.md` に作成する。

---

## 更新履歴

- 2025-12-31: 初版作成
