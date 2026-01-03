---
date: 2025-12-31T01:45:00+09:00
description: RSSリーダー / ニューススクレイパー連載のための調査・情報収集ドキュメント
draft: true
title: '調査結果 - RSSリーダー / ニューススクレイパー'
---

# 調査結果：RSSリーダー / ニューススクレイパー

## 調査概要

- **調査日**: 2025-12-31
- **テーマ**: RSSリーダー / ニューススクレイパー
- **技術スタック**: Perl
- **想定読者**: Perl入学式卒業程度、「Mooで覚えるオブジェクト指向プログラミング」シリーズ読了者
- **学習目標**: 自然に覚えるデザインパターン
- **各回の制約**: コード例2つまで、新しい概念1つまで

---

## 1. キーワード・関連トピックの調査

### 1.1 XML::LibXML（XMLパース）

#### 要点

- XML::LibXMLはlibxml2のPerlバインディングで、高速かつ堅牢なXMLパーサ
- DOM、SAX、XPathをサポートし、RSSやAtomフィードのパースに最適
- XPathクエリによる柔軟なノード検索が可能
- 名前空間付きXML（RSS 1.0など）もXPathContextで対応可能

#### コード例（RSS 2.0パース）

```perl
use strict;
use warnings;
use XML::LibXML;

my $dom = XML::LibXML->load_xml(location => 'rss.xml');

foreach my $item ($dom->findnodes('//item')) {
    my $title = $item->findvalue('title');
    my $link = $item->findvalue('link');
    print "$title: $link\n";
}
```

#### 情報源

| リソース | URL | 信頼度 |
|---------|-----|-------|
| CPAN公式ドキュメント | https://metacpan.org/dist/XML-LibXML/view/LibXML.pod | ★★★★★ |
| Perl XML::LibXML by Example | https://grantm.github.io/perl-libxml-by-example/ | ★★★★★ |
| Stack Overflow RSSパース例 | https://stackoverflow.com/questions/7434676/parse-rss-feed-with-perl-using-xmllibxml | ★★★★☆ |
| Perl for XML Processing | https://perl-begin.org/uses/xml/ | ★★★★☆ |

#### 根拠

- XML::LibXMLはCPANで最も利用されているXMLパーサの一つ
- libxml2ライブラリに基づいており、パフォーマンスと信頼性が高い
- 公式ドキュメントと実践的なチュートリアルが充実

---

### 1.2 Web::Query（スクレイピング）

#### 要点

- jQueryライクなセレクタ構文でHTMLをパース・操作できるモジュール
- CSSセレクタによる要素選択が可能
- `find()`, `each()`, `text()`, `attr()` などのメソッドを提供
- LWP::UserAgentやHTTP::Tinyと組み合わせてWebページを取得

#### コード例（基本的なスクレイピング）

```perl
use strict;
use warnings;
use LWP::UserAgent;
use Web::Query;

my $ua = LWP::UserAgent->new();
my $response = $ua->get('https://example.com');
die "Error: " . $response->status_line unless $response->is_success;

my $wq = Web::Query->new($response->decoded_content);

$wq->find('h2.product-title')->each(sub {
    print $_->text, "\n";
});
```

#### 情報源

| リソース | URL | 信頼度 |
|---------|-----|-------|
| Web::Query CPAN | https://metacpan.org/pod/Web::Query | ★★★★★ |
| ZenRows Perl Web Scraping | https://www.zenrows.com/blog/perl-web-scraping | ★★★★☆ |
| Rayobyte Perl Tutorial | https://rayobyte.com/blog/perl-web-scraping-tutorial/ | ★★★★☆ |
| ScrapingBee Perl Guide | https://www.scrapingbee.com/blog/web-scraping-perl/ | ★★★☆☆ |

#### 根拠

- Web::QueryはjQueryに慣れた開発者にとって直感的
- HTML::TreeBuilderより簡潔な記述が可能
- 実際のスクレイピングプロジェクトで広く利用されている

---

### 1.3 RSSフィード仕様（RSS 2.0 / Atom）

#### 要点

| 属性 | RSS 2.0 | Atom 1.0 |
|-----|---------|----------|
| ルート要素 | `<rss>` | `<feed>` |
| アイテム要素 | `<item>` | `<entry>` |
| 日付形式 | RFC-822 | RFC 3339 (ISO 8601) |
| コンテンツ型 | 暗黙的 | 明示的（`type`属性） |
| 拡張性 | 限定的 | 名前空間で柔軟 |
| 標準化 | 非公式 | IETF (RFC 4287) |

#### RSS 2.0の基本構造

```xml
<rss version="2.0">
  <channel>
    <title>フィードタイトル</title>
    <link>http://example.com</link>
    <description>説明文</description>
    <item>
      <title>記事タイトル</title>
      <link>http://example.com/article</link>
      <description>記事の要約</description>
      <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
```

#### Atomの基本構造

```xml
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>フィードタイトル</title>
  <link href="http://example.com"/>
  <updated>2024-01-01T00:00:00Z</updated>
  <entry>
    <title>記事タイトル</title>
    <link href="http://example.com/article"/>
    <id>tag:example.com,2024:article</id>
    <updated>2024-01-01T00:00:00Z</updated>
    <summary>記事の要約</summary>
  </entry>
</feed>
```

#### 情報源

| リソース | URL | 信頼度 |
|---------|-----|-------|
| RSS 2.0仕様（公式） | https://www.rssboard.org/rss-specification | ★★★★★ |
| Atom RFC 4287 | https://datatracker.ietf.org/doc/html/rfc4287 | ★★★★★ |
| Wikipedia Atom | https://en.wikipedia.org/wiki/Atom_(Web_standard) | ★★★★☆ |
| RSS vs Atom比較 | https://thisvsthat.io/atom-vs-rss | ★★★☆☆ |

#### 仮定

- 多くのブログやニュースサイトはRSS 2.0を採用している
- 両フォーマットに対応することで、より多くのサイトをサポート可能

---

### 1.4 Perlでの定期実行

#### 要点

**方法1: システムcron（推奨）**

- Unix/Linuxのcrontabを使用
- 絶対パスを使用することが重要
- 出力をログファイルにリダイレクト

```sh
# 毎時0分に実行
0 * * * * /usr/bin/perl /path/to/rss_reader.pl >> /var/log/rss.log 2>&1

# 毎日午前6時に実行
0 6 * * * /usr/bin/perl /path/to/rss_reader.pl
```

**方法2: Schedule::Cron（Perl内蔵）**

```perl
use Schedule::Cron;

my $cron = Schedule::Cron->new(sub { print "実行: " . localtime . "\n" });
$cron->add_entry("0 * * * *");  # 毎時0分
$cron->run;
```

#### 情報源

| リソース | URL | 信頼度 |
|---------|-----|-------|
| perl.com cronガイド | https://www.perl.com/article/43/2013/10/11/How-to-schedule-Perl-scripts-using-cron/ | ★★★★★ |
| Schedule::Cron CPAN | https://metacpan.org/pod/Schedule::Cron | ★★★★★ |
| PerlMaven 自動実行 | https://perlmaven.com/how-to-run-a-perl-script-automatically-every | ★★★★☆ |

#### 根拠

- cronはUnix系OSで標準的かつ信頼性が高い
- Schedule::Cronは動的なスケジューリングが必要な場合に有用

---

### 1.5 関連CPANモジュール

#### RSSパース用モジュール比較

| モジュール | 特徴 | 推奨用途 |
|-----------|------|---------|
| **XML::LibXML** | 高速・汎用・XPath対応 | 本連載で使用（推奨） |
| XML::RSS | クラシック・シンプル | 標準的なRSSパース |
| XML::RSS::LibXML | XML::RSS互換でLibXML使用 | 高速化が必要な場合 |
| XML::Feed | RSS/Atom統合API | 両フォーマット対応 |
| XML::RSSLite | 緩いパース（正規表現） | 非標準フィード対応 |

#### スクレイピング用モジュール比較

| モジュール | 特徴 | 推奨用途 |
|-----------|------|---------|
| **Web::Query** | jQueryライク・簡潔 | 本連載で使用（推奨） |
| HTML::TreeBuilder | DOM構築・堅牢 | 複雑なHTML操作 |
| WWW::Mechanize | フォーム操作・自動化 | ログイン必要なサイト |
| HTTP::Tiny | 軽量HTTP | シンプルな取得 |
| LWP::UserAgent | 高機能HTTP | 本格的なクローリング |

---

## 2. 競合記事の分析

### 2.1 日本語リソース

| 記事/サイト | 特徴 | 対象レベル | 差別化ポイント |
|------------|------|-----------|---------------|
| モダンなPerl入門 - RSS parse | XML::Feedを使った基本解説 | 初級 | シンプルだがデザインパターンには触れない |
| perl-users.jp XML::Feed | 実践的なRSSパース例 | 中級 | Mooとの組み合わせがない |

**URL**:
- https://perl-users.jp/modern_introduction_perl/rss_parse.html
- https://perl-users.jp/modules/xml_feed.html

### 2.2 英語リソース

| 記事/サイト | 特徴 | 対象レベル | 差別化ポイント |
|------------|------|-----------|---------------|
| Perl XML::LibXML by Example | 非常に詳細なXML::LibXMLガイド | 中級〜上級 | RSSに特化していない |
| ZenRows Perl Scraping | 最新のスクレイピングチュートリアル | 初級〜中級 | デザインパターンには触れない |
| Rayobyte Tutorial | 各種モジュール比較 | 中級 | 実践的だがOOP指向ではない |

### 2.3 差別化のポイント

本連載では以下の点で差別化を図る：

1. **Mooを活用したOOPアプローチ**: 既存の前提知識を活かす
2. **デザインパターンの自然な導入**: Strategyパターン、Adapterパターン
3. **段階的な機能追加**: 小さな改善を積み重ねる学習体験
4. **日本語での詳細な解説**: Perl入学式卒業レベル向け

---

## 3. 内部リンク候補

### 3.1 必須リンク（前提記事）

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|-------|
| `/content/post/2025/12/30/163820.md` | `/2025/12/30/163820/` | 第12回-型チェックでバグを未然に防ぐ - Mooで覚えるオブジェクト指向プログラミング | ★★★★★ |

### 3.2 関連シリーズ

| ファイル | 内部リンク | タイトル | 関連度 |
|---------|-----------|---------|-------|
| `/content/post/2025/12/30/164012.md` | `/2025/12/30/164012/` | 第12回-これがデザインパターンだ！ - Mooを使ってディスパッチャーを作ってみよう | ★★★★★ |
| `/content/post/2025/12/30/164001.md` | `/2025/12/30/164001/` | 第1回-BBSに機能を追加しよう - Mooを使ってディスパッチャーを作ってみよう | ★★★★☆ |

### 3.3 タグ別関連記事

調査したタグと関連ファイル：

- **perl**: `/content/post/2025/11/27/204639.md` → `/2025/11/27/204639/`
- **moo**: 2025/12/30の連載記事群
- **types**: `/content/post/2025/12/30/163820.md` → `/2025/12/30/163820/`

---

## 4. デザインパターンとの関連

### 4.1 本連載で自然に学べるパターン

| パターン | 適用場面 | 学習効果 |
|---------|---------|---------|
| **Strategy** | RSS/Atom/スクレイピングの切り替え | アルゴリズムのカプセル化 |
| **Adapter** | 異なるフィード形式の統一インターフェース | 互換性の確保 |
| **Factory** | フィード種別に応じたパーサ生成 | オブジェクト生成の抽象化 |
| **Template Method** | パース処理の共通フロー定義 | 処理の骨格を定義 |

### 4.2 Strategyパターンの例（RSSリーダーへの適用）

```perl
# 基底クラス（ロールとして実装可能）
package FeedParser::Role;
use Moo::Role;
requires 'parse';

# RSS用パーサ
package FeedParser::RSS;
use Moo;
with 'FeedParser::Role';

sub parse {
    my ($self, $content) = @_;
    # RSS 2.0のパース処理
}

# Atom用パーサ
package FeedParser::Atom;
use Moo;
with 'FeedParser::Role';

sub parse {
    my ($self, $content) = @_;
    # Atomのパース処理
}
```

### 4.3 参考リソース

| リソース | URL | 信頼度 |
|---------|-----|-------|
| Design Patterns in Modern Perl | https://github.com/manwar/design-patterns | ★★★★☆ |
| Class::Adapter CPAN | https://metacpan.org/pod/Class::Adapter | ★★★★★ |
| GeeksforGeeks Adapter Pattern | https://www.geeksforgeeks.org/system-design/adapter-pattern/ | ★★★★☆ |

---

## 5. 技術的正確性を担保するための情報源リスト

### 5.1 公式ドキュメント（最優先参照）

| リソース | URL | 用途 |
|---------|-----|------|
| XML::LibXML CPAN | https://metacpan.org/dist/XML-LibXML | XMLパースのリファレンス |
| Web::Query CPAN | https://metacpan.org/pod/Web::Query | スクレイピングのリファレンス |
| Moo CPAN | https://metacpan.org/pod/Moo | OOPのリファレンス |
| Type::Tiny CPAN | https://metacpan.org/pod/Type::Tiny | 型制約のリファレンス |
| LWP::UserAgent CPAN | https://metacpan.org/pod/LWP::UserAgent | HTTP通信のリファレンス |

### 5.2 仕様書

| リソース | URL | 用途 |
|---------|-----|------|
| RSS 2.0仕様 | https://www.rssboard.org/rss-specification | RSS形式の正確な理解 |
| Atom RFC 4287 | https://datatracker.ietf.org/doc/html/rfc4287 | Atom形式の正確な理解 |
| XPath仕様 | https://www.w3.org/TR/xpath/ | XPathクエリの理解 |

### 5.3 チュートリアル・ガイド

| リソース | URL | 用途 |
|---------|-----|------|
| Perl XML::LibXML by Example | https://grantm.github.io/perl-libxml-by-example/ | 実践的なXML処理 |
| モダンなPerl入門 | https://perl-users.jp/ | 日本語でのPerl学習 |
| PerlMaven | https://perlmaven.com/ | 各種Perlトピック |

---

## 6. 連載構造案への提言

### 6.1 学習の流れ（案）

1. **導入**: お気に入りサイトの新着を取得したい（動機付け）
2. **HTTP取得**: LWP::UserAgentでRSSフィードを取得
3. **XMLパース基礎**: XML::LibXMLでRSS 2.0をパース
4. **クラス設計**: Mooでパーサクラスを作成
5. **複数フォーマット対応**: Atomパーサの追加（Strategyパターン導入）
6. **スクレイピング**: Web::Queryで非RSS対応サイトを処理
7. **統一インターフェース**: Adapterパターンで統合
8. **設定管理**: フィードリストの管理
9. **定期実行**: cronによる自動取得
10. **出力**: HTMLやターミナルへの表示
11. **拡張**: 既読管理やフィルタリング
12. **まとめ**: デザインパターンの振り返り

### 6.2 新しい概念（1回1概念）

| 回 | 新しい概念 | 関連パターン |
|---|-----------|-------------|
| 1 | LWP::UserAgentによるHTTP取得 | - |
| 2 | XML::LibXMLによるXMLパース | - |
| 3 | XPathによるノード検索 | - |
| 4 | パーサクラスの設計 | - |
| 5 | ロールによる共通インターフェース | Strategy準備 |
| 6 | 複数パーサの切り替え | Strategy |
| 7 | Web::Queryによるスクレイピング | - |
| 8 | 異なるソースの統合 | Adapter |
| 9 | 設定ファイルの読み込み | - |
| 10 | cronによる定期実行 | - |
| 11 | 出力フォーマットの選択 | Strategy応用 |
| 12 | デザインパターンの振り返り | まとめ |

---

## 7. 仮定と注意点

### 7.1 仮定

1. 読者はMooの基本（has, sub, new, extends, with, handles, isa）を理解済み
2. 読者はPerl入学式レベルの基礎知識を持つ
3. 対象サイトはRSS 2.0またはAtomフィードを提供している
4. スクレイピングは利用規約を遵守して行う

### 7.2 注意点

1. **robots.txt遵守**: スクレイピング時はサイトのポリシーを確認
2. **リクエスト間隔**: 過度なアクセスを避ける（1秒以上のインターバル推奨）
3. **エラーハンドリング**: ネットワークエラーやパースエラーへの対応
4. **文字コード**: UTF-8以外の文字コードへの対応が必要な場合がある

---

## 8. まとめ

本調査では、RSSリーダー/ニューススクレイパー連載のための技術的基盤を整理した。

**主要な技術選択**:
- XMLパース: **XML::LibXML**（XPath対応、高速、堅牢）
- スクレイピング: **Web::Query**（jQueryライク、簡潔）
- OOP: **Moo**（前シリーズからの継続）
- HTTP: **LWP::UserAgent**（高機能、信頼性）

**デザインパターンの自然な導入**:
- **Strategyパターン**: RSS/Atom/スクレイピングの切り替え
- **Adapterパターン**: 異なるソースの統一インターフェース

**差別化ポイント**:
- 前シリーズのMoo知識を活かしたOOPアプローチ
- デザインパターンを「自然に身につける」ストーリー展開
- 日本語での丁寧な解説（Perl入学式卒業レベル対応）

---

*調査完了: 2025-12-31*
