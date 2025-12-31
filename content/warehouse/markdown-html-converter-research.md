---
title: "調査ドキュメント - Markdown HTML変換ツール シリーズ記事"
date: 2025-12-31T10:06:38+09:00
draft: true
tags:
  - perl
  - markdown
  - regex
  - http
  - research
description: "シリーズ記事「Markdown HTML変換ツールを作ってみよう」の執筆に必要な情報調査"
---

# 調査ドキュメント：Markdown HTML変換ツール シリーズ記事

## 調査目的

シリーズ記事「Markdown HTML変換ツールを作ってみよう」の執筆に必要な情報を調査・収集する。

- **技術スタック**: Perl
- **テーマ**: Markdown HTML変換ツール
- **学習内容**: 正規表現、文字列処理、モジュール（Text::Markdownなど）
- **シリーズのゴール**: HTTP通信ができる、APIを利用できる、自然に覚えるデザインパターン
- **想定読者**: Perl入学式卒業程度、「第12回-型チェックでバグを未然に防ぐ - Mooで覚えるオブジェクト指向プログラミング」を読了
- **各回の制約**: コード例は2つまで、新しい概念は1つまで
- **調査実施日**: 2025年12月31日

---

## 1. キーワード調査

### 1.1 Markdown記法の種類

**要点**:

Markdownは軽量マークアップ言語で、以下の主要な記法がある：

| 記法カテゴリ | 記法例 | HTML出力 |
|------------|--------|---------|
| **見出し** | `# 見出し1`、`## 見出し2` | `<h1>`、`<h2>` |
| **強調** | `*斜体*`、`**太字**` | `<em>`、`<strong>` |
| **リスト** | `- 項目`、`1. 項目` | `<ul><li>`、`<ol><li>` |
| **リンク** | `[テキスト](URL)` | `<a href="URL">` |
| **画像** | `![alt](URL)` | `<img src="URL" alt="">` |
| **コードブロック** | `` `コード` ``、```言語 | `<code>`、`<pre><code>` |
| **引用** | `> 引用文` | `<blockquote>` |
| **水平線** | `---` | `<hr>` |

**根拠**:

- CommonMark仕様（標準化されたMarkdown仕様）
- GitHub Flavored Markdown（GFM）仕様

**出典**:

- CommonMark Spec: https://spec.commonmark.org/
- GitHub Flavored Markdown Spec: https://github.github.com/gfm/

**信頼度**: 高（公式仕様書）

---

### 1.2 Perlでの正規表現によるテキスト変換パターン

**要点**:

Perlは正規表現を言語レベルでサポートしており、テキスト変換に最適：

```perl
# 基本の置換構文
$text =~ s/パターン/置換後/;

# 全置換（gオプション）
$text =~ s/パターン/置換後/g;

# 大文字小文字無視（iオプション）
$text =~ s/パターン/置換後/gi;

# 複数行処理（mオプション）
$text =~ s/^パターン/置換後/gm;
```

**Markdown変換に使える正規表現パターン例**:

| Markdown | 正規表現パターン | 置換後 |
|----------|----------------|--------|
| 見出し（H1） | `s/^# (.+)$/<h1>$1<\/h1>/gm` | `<h1>見出し</h1>` |
| 太字 | `s/\*\*(.+?)\*\*/<strong>$1<\/strong>/g` | `<strong>太字</strong>` |
| 斜体 | `s/\*(.+?)\*/<em>$1<\/em>/g` | `<em>斜体</em>` |
| リンク | `s/\[(.+?)\]\((.+?)\)/<a href="$2">$1<\/a>/g` | `<a href="URL">テキスト</a>` |

**根拠**:

- perlre（Perl正規表現）ドキュメント
- perlretut（Perl正規表現チュートリアル）

**出典**:

- perlretut: https://perldoc.jp/docs/perl/5.18.1/perlretut.pod
- とほほのWWW入門: https://www.tohoho-web.com/perl/replace.htm
- Perl正規表現解説: https://www.bold.ne.jp/engineer-club/perl-regular-expression

**信頼度**: 高（公式ドキュメントおよび著名な技術サイト）

---

### 1.3 Text::Markdown、Text::MultiMarkdownなどのCPANモジュール

**要点**:

| モジュール名 | 特徴 | 最終更新 |
|-------------|------|---------|
| **Text::Markdown** | 標準的なMarkdown実装、John Gruberのオリジナル仕様に準拠 | 2024年更新 |
| **Text::MultiMarkdown** | 拡張Markdown対応（テーブル、脚注、定義リストなど） | 安定版 |
| **Text::Markdown::Discount** | C言語実装のDiscountのPerlバインディング、高速 | 高パフォーマンス |

**Text::Markdownの基本的な使い方**:

```perl
# 関数インターフェース
use Text::Markdown 'markdown';
my $html = markdown($markdown_text);

# オブジェクト指向インターフェース
use Text::Markdown;
my $parser = Text::Markdown->new;
my $html = $parser->markdown($markdown_text);
```

**オプション**:

- `empty_element_suffix`: 空要素の終端（`>` または `/>`）
- `tab_width`: タブ幅の設定
- `trust_list_start_value`: 番号付きリストの開始値を信頼

**根拠**:

- MetaCPAN公式ドキュメント

**出典**:

- Text::Markdown: https://metacpan.org/pod/Text::Markdown
- Text::MultiMarkdown: https://metacpan.org/pod/Text::MultiMarkdown
- GitHub: https://github.com/bobtfish/text-markdown

**信頼度**: 高（CPAN公式）

---

### 1.4 HTTP通信モジュール（HTTP::Tiny, LWP::UserAgent）

**要点**:

PerlでHTTP通信を行う主要なモジュール：

| モジュール | 特徴 | 用途 |
|-----------|------|------|
| **HTTP::Tiny** | 軽量、依存少、Perlコアに含まれる（5.14+） | シンプルなAPI通信 |
| **LWP::UserAgent** | 高機能、Cookie管理、認証、プロキシ対応 | 複雑なWeb通信 |
| **Mojo::UserAgent** | Mojolicious付属、非同期対応、モダンAPI | Mojoliciousアプリ |

**HTTP::Tinyの基本的な使い方**:

```perl
use HTTP::Tiny;

my $http = HTTP::Tiny->new;

# GETリクエスト
my $response = $http->get('https://api.example.com/data');
if ($response->{success}) {
    print $response->{content};
}

# POSTリクエスト
my $response = $http->post('https://api.example.com/post', {
    content => '{"key":"value"}',
    headers => { 'content-type' => 'application/json' },
});
```

**LWP::UserAgentの基本的な使い方**:

```perl
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my $response = $ua->get('https://api.example.com/data');
if ($response->is_success) {
    print $response->decoded_content;
}
```

**根拠**:

- Perl公式ドキュメント
- CPAN公式ドキュメント

**出典**:

- HTTP::Tiny: https://perldoc.perl.org/HTTP::Tiny
- LWP::UserAgent: https://metacpan.org/pod/LWP::UserAgent
- 日本語解説: https://code-notes.com/lesson/39

**信頼度**: 高（公式ドキュメント）

---

### 1.5 API利用パターン（JSON処理、リクエスト/レスポンス）

**要点**:

PerlでのJSON処理：

```perl
use JSON;

# エンコード（Perl → JSON）
my $json_text = encode_json($perl_data);

# デコード（JSON → Perl）
my $perl_data = decode_json($json_text);
```

**APIリクエスト/レスポンスの基本パターン**:

```perl
use HTTP::Tiny;
use JSON;

my $http = HTTP::Tiny->new;

# APIリクエスト
my $response = $http->get('https://api.example.com/markdown', {
    headers => { 'Accept' => 'application/json' }
});

if ($response->{success}) {
    my $data = decode_json($response->{content});
    # データ処理
}
```

**根拠**:

- JSON.pm公式ドキュメント

**出典**:

- JSON: https://metacpan.org/pod/JSON
- JSON::XS: https://metacpan.org/pod/JSON::XS

**信頼度**: 高

---

### 1.6 デザインパターン（変換処理に適したパターン）

**要点**:

Markdown変換ツールに適用可能なデザインパターン：

| パターン | 適用場面 | 説明 |
|---------|---------|------|
| **Strategy** | 要素ごとの変換処理 | 見出し、リスト、リンクなど要素タイプ別の変換戦略を切り替え |
| **Template Method** | 変換のワークフロー | 「解析 → 変換 → 出力」の骨格を定義し、詳細はサブクラスで |
| **Chain of Responsibility** | 変換パイプライン | 複数の変換処理を連鎖させる |
| **Decorator** | 機能拡張 | 基本変換に追加機能（シンタックスハイライト等）を付加 |
| **Factory Method** | パーサー生成 | 入力形式に応じたパーサーを動的に生成 |

**Strategyパターンの適用例**:

```perl
# 変換戦略のインターフェース（ロール）
package ConverterRole {
    use Moo::Role;
    requires 'convert';
}

# 見出し変換戦略
package HeaderConverter {
    use Moo;
    with 'ConverterRole';

    sub convert {
        my ($self, $text) = @_;
        $text =~ s/^# (.+)$/<h1>$1<\/h1>/gm;
        return $text;
    }
}
```

**根拠**:

- GoFデザインパターン
- Markdown変換ツールの一般的な実装パターン

**出典**:

- Refactoring Guru: https://refactoring.guru/design-patterns
- 本リポジトリ内 design-patterns-research.md

**信頼度**: 高

---

## 2. 競合記事の分析

### 2.1 Markdown変換に関する既存記事

| 記事タイトル/サイト | 言語 | 特徴 | URL |
|-------------------|------|------|-----|
| **Markdown Guide** | 英語 | 包括的なMarkdownリファレンス | https://www.markdownguide.org/ |
| **CommonMark Tutorial** | 英語 | 標準仕様に基づくチュートリアル | https://commonmark.org/help/ |
| **Qiita - Markdown記法** | 日本語 | 日本語での詳細解説 | Qiita内多数 |

### 2.2 Perlでの正規表現チュートリアル

| 記事/リソース | 特徴 | URL |
|--------------|------|-----|
| **perlretut** | Perl公式チュートリアル | https://perldoc.jp/docs/perl/5.18.1/perlretut.pod |
| **とほほのWWW入門** | 日本語でわかりやすい | https://www.tohoho-web.com/perl/replace.htm |
| **KentWeb** | 基礎から学べる | https://www.kent-web.com/perl/chap7.html |

### 2.3 PerlでのHTTP通信、API利用チュートリアル

| 記事/リソース | 特徴 | URL |
|--------------|------|-----|
| **ソースコードで学ぶ** | 実践的なAPI接続例 | https://code-notes.com/lesson/39 |
| **Japanシーモア** | LWP::UserAgent詳細解説 | https://jp-seemore.com/sys/20283/ |

### 2.4 差別化ポイント

**既存記事の課題**:

1. 正規表現とモジュール利用を分離して解説している記事が多い
2. HTTP通信やAPI利用までの発展的な内容がない
3. デザインパターンとの関連付けがない
4. Mooシリーズとの連続性がない

**本シリーズの強み**:

1. 正規表現による手動実装からモジュール利用まで段階的に学習
2. HTTP通信、API利用まで発展させる
3. デザインパターン（特にStrategy）を自然に学べる
4. Mooシリーズ読了者向けに、オブジェクト指向の知識を活かせる

---

## 3. 内部リンク調査

`/content/post` 配下のファイルをgrepで調査し、関連トピックの既存記事を特定した。

### 3.1 正規表現関連

| ファイルパス | タイトル（推定） | 内部リンク |
|-------------|----------------|-----------|
| `/content/post/2009/02/28/024557.md` | 正規表現関連 | `/2009/02/28/024557/` |
| `/content/post/2015/09/18/124408.md` | 正規表現関連 | `/2015/09/18/124408/` |
| `/content/post/2016/12/02/001419.md` | 正規表現関連 | `/2016/12/02/001419/` |

### 3.2 オブジェクト指向（Mooシリーズ）

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2021/10/31/191008.md` | 第1回-Mooで覚えるオブジェクト指向プログラミング | `/2021/10/31/191008/` | **非常に高** |
| `/content/post/2025/12/30/163820.md` | 第12回-型チェックでバグを未然に防ぐ - Mooで覚えるオブジェクト指向プログラミング | `/2025/12/30/163820/` | **非常に高（前提記事）** |

### 3.3 HTTP通信・API関連

| ファイルパス | タイトル（推定） | 内部リンク |
|-------------|----------------|-----------|
| `/content/post/2014/06/16/004553.md` | API関連 | `/2014/06/16/004553/` |
| `/content/post/2014/06/21/134656.md` | API関連 | `/2014/06/21/134656/` |

### 3.4 Mojolicious関連

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2015/02/02/075435.md` | Mojolicious関連 | `/2015/02/02/075435/` |
| `/content/post/2015/02/04/075756.md` | Mojolicious関連 | `/2015/02/04/075756/` |

### 3.5 JSON-RPC関連

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2015/11/16/083646.md` | JSON::RPC::Spec v1.0.5 をリリースしました | `/2015/11/16/083646/` |
| `/content/post/2014/08/14/122638.md` | CPAN Authorになりました | `/2014/08/14/122638/` |
| `/content/post/2014/08/14/221829.md` | JSON::RPC::Specをバージョンアップしました | `/2014/08/14/221829/` |
| `/content/post/2025/12/25/234500.md` | JSON-RPC Request/Response実装 | `/2025/12/25/234500/` |

### 3.6 Markdown関連

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2013/02/09/162200.md` | あの reveal.js でのプレゼンを Markdown で簡単に書けるようにした | `/2013/02/09/162200/` |
| `/content/post/2016/03/21/114416.md` | Markdown関連 | `/2016/03/21/114416/` |

### 3.7 デザインパターン関連

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2025/12/30/164012.md` | 第12回-これがデザインパターンだ！（ディスパッチャーシリーズ） | `/2025/12/30/164012/` |
| `/content/post/2025/12/25/234500.md` | Factoryパターン言及 | `/2025/12/25/234500/` |

### 3.8 Perlの歴史・コミュニティ

| ファイルパス | タイトル | 内部リンク |
|-------------|---------|-----------|
| `/content/post/2025/12/24/000000.md` | Perlの歴史とコミュニティ - YAPC, Kansai.pm, そしてこれから | `/2025/12/24/000000/` |

---

## 4. 情報源リスト

技術的な正確性を担保するための重要なリソース：

### 4.1 公式ドキュメント

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **perldoc** | https://perldoc.perl.org/ | Perl公式リファレンス |
| **MetaCPAN** | https://metacpan.org/ | CPANモジュール公式 |
| **CommonMark Spec** | https://spec.commonmark.org/ | Markdown仕様 |
| **GFM Spec** | https://github.github.com/gfm/ | GitHub Flavored Markdown仕様 |

### 4.2 CPANモジュールドキュメント

| モジュール | URL |
|-----------|-----|
| **Text::Markdown** | https://metacpan.org/pod/Text::Markdown |
| **Text::MultiMarkdown** | https://metacpan.org/pod/Text::MultiMarkdown |
| **HTTP::Tiny** | https://perldoc.perl.org/HTTP::Tiny |
| **LWP::UserAgent** | https://metacpan.org/pod/LWP::UserAgent |
| **JSON** | https://metacpan.org/pod/JSON |
| **Moo** | https://metacpan.org/pod/Moo |
| **Types::Standard** | https://metacpan.org/pod/Types::Standard |

### 4.3 日本語リソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **perldoc.jp** | https://perldoc.jp/ | Perl公式ドキュメント日本語訳 |
| **とほほのWWW入門** | https://www.tohoho-web.com/ | わかりやすい日本語解説 |
| **Perl入学式** | https://perl-entrance.org/ | 初心者向けコミュニティ |

### 4.4 デザインパターン

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **Refactoring Guru** | https://refactoring.guru/design-patterns | 視覚的な解説 |
| **本リポジトリ内** | `content/warehouse/design-patterns-research.md` | 内部調査ドキュメント |

### 4.5 書籍（参考）

| 書籍名 | ASIN/ISBN | 備考 |
|-------|-----------|------|
| **プログラミングPerl 第4版** | 978-4873116686 | Perl定番書籍 |
| **正規表現詳説 第3版** | 978-4873114507 | 正規表現のバイブル |
| **Webを支える技術** | 978-4774142043 | HTTP/REST理解に |

---

## 5. 発見・結論

### 5.1 主要な発見

1. **Perlは正規表現に最適**: 言語レベルでの正規表現サポートにより、Markdown変換の実装が簡潔に記述できる

2. **段階的な学習パスが構築可能**:
   - 第1段階: 正規表現による手動実装（基礎理解）
   - 第2段階: Text::Markdownモジュール活用（実践的な選択）
   - 第3段階: HTTP通信でAPIと連携（応用）

3. **デザインパターンとの親和性**: StrategyパターンやTemplate Methodパターンを自然に学べる題材である

4. **Mooシリーズとの連続性**: 第12回で学んだ型制約（Types::Standard）をそのまま活用できる

### 5.2 シリーズ構成の提案（概要）

| 回 | 主題 | 新しい概念 |
|----|------|-----------|
| 1 | 正規表現で見出しを変換する | 置換演算子 s/// |
| 2 | 複数のパターンを変換する | パターンマッチとキャプチャ |
| 3 | 変換処理をクラスにまとめる | モジュール分割 |
| 4 | Text::Markdownを使ってみる | CPANモジュールの活用 |
| 5 | 変換戦略を切り替える | Strategyパターン |
| 6 | HTTP通信でMarkdownを取得する | HTTP::Tiny |
| 7 | JSONレスポンスを処理する | JSONエンコード/デコード |
| 8 | APIクライアントを作る | クラス設計 |
| ... | ... | ... |

### 5.3 仮定・前提条件

- 読者は「第12回-型チェックでバグを未然に防ぐ - Mooで覚えるオブジェクト指向プログラミング」を読了している
- 読者はPerlの基本文法（変数、配列、ハッシュ、サブルーチン）を理解している
- 読者はcpanmによるモジュールインストールができる

### 5.4 不明点・今後の調査が必要な領域

- シリーズの具体的な回数（全何回にするか）
- HTTP通信とAPI利用の具体的な題材（どのAPIを使うか）
- デザインパターンをどこまで深掘りするか

---

## 6. 調査コマンド・手法

本調査で使用したコマンドおよび手法：

```bash
# 正規表現関連記事の検索
grep -ri '正規表現\|regexp\|regex' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# オブジェクト指向（Moo）関連記事の検索
grep -ri 'Moo\|オブジェクト指向\|object-oriented' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# HTTP通信関連記事の検索
grep -ri 'HTTP\|http通信\|LWP\|HTTP::Tiny' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# API関連記事の検索
grep -ri 'API\|api' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# Mojolicious関連記事の検索
grep -ri 'Mojolicious\|mojo' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# JSON-RPC関連記事の検索
grep -ri 'JSON-RPC\|jsonrpc' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# Markdown関連記事の検索
grep -ri 'Markdown\|マークダウン' /home/runner/work/www.nqou.net/www.nqou.net/content/post

# Text::Markdown関連記事の検索
grep -ri 'Text::Markdown\|Text::MultiMarkdown' /home/runner/work/www.nqou.net/www.nqou.net/content/post
```

---

**調査完了**: 2025年12月31日
**担当**: investigative-research エージェント
