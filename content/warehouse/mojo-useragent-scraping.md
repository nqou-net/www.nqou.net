---
date: 2025-12-30T09:35:22+00:00
description: 「Mojo::UserAgentでスクレイピング入門」技術記事執筆のための調査・情報収集ドキュメント
draft: true
tags:
  - perl
  - mojo-useragent
  - web-scraping
  - mojo-dom
  - research
title: 調査：Mojo::UserAgentでスクレイピング入門
---

## 調査概要

- **調査目的**: 「Mojo::UserAgentでスクレイピング入門」というテーマの技術記事執筆のための情報収集
- **実施日**: 2025-12-30
- **想定読者**: 基本的なプログラミングの知識はある初心者
- **想定ペルソナ**: Perlでウェブサイトのスクレイピングをして、情報を取得したい
- **目標**: Perlでウェブサイトのスクレイピングができるようになる

---

## 1. Mojo::UserAgentの最新情報と特徴

### 1.1 最新バージョン情報

| 項目 | 情報 |
|------|------|
| ライブラリ名 | Mojo::UserAgent |
| 所属ディストリビューション | Mojolicious |
| 最新バージョン | 9.40〜9.42 (2024-2025年) |
| 主な更新 | resumable file downloads (EXPERIMENTAL), download methods, cookie handling改善 |

**出典**:
- https://metacpan.org/dist/Mojolicious/changes (信頼度: 高)
- https://metacpan.org/pod/Mojo::UserAgent (信頼度: 高)

### 1.2 主な機能

1. **Non-blocking I/O**: 非同期・並行HTTPリクエストをサポート
2. **統合HTML/XML解析**: Mojo::DOMによるCSSセレクタでの要素抽出
3. **プロキシサポート**: HTTP/SOCKS5プロキシに対応
4. **Cookie jar**: Netscape形式の永続Cookie対応
5. **自動圧縮・リダイレクト処理**: gzip、リダイレクトを透過的に処理
6. **Promises/A+対応**: モダンな非同期パターン
7. **WebSocketサポート**: リアルタイム通信にも対応
8. **TLS/SNI対応**: セキュアな通信

### 1.3 競合ライブラリとの比較

| 機能 | Mojo::UserAgent | LWP::UserAgent | Web::Scraper |
|------|----------------|----------------|--------------|
| ブロッキングリクエスト | ○ | ○ | - |
| 非同期リクエスト | ○ | × | × |
| SSL/TLS対応 | ○ | ○ | - |
| プロキシサポート | ○ | ○ | - |
| Cookie管理 | ○ | ○ | - |
| WebSocket | ○ | × | × |
| DOM/CSSセレクタ解析 | ○ (Mojo::DOM) | × (別途必要) | ○ |
| 保守状態 | 活発 | 安定 | 低調 |

**要点**:
- LWP::UserAgentは同期処理のみだが、安定性が高く歴史がある
- Mojo::UserAgentはモダンで非同期対応、DOM解析も統合されている
- Web::Scraperは直感的なDSLを持つが、メンテナンスが低調

**出典**:
- https://brightdata.com/blog/web-data/web-scraping-with-perl (信頼度: 中)
- https://stackoverflow.com/questions/64545805/matching-methods-from-lwpuseragent-to-mojouseragent (信頼度: 中)

---

## 2. スクレイピングの基本概念

### 2.1 HTTP通信の基礎

#### GETリクエスト
- URLに対してリソースを取得するリクエスト
- パラメータはURLのクエリストリングで渡す

```perl
my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://example.com/page?id=123')->result;
```

#### POSTリクエスト
- サーバーにデータを送信するリクエスト
- フォームデータやJSONをボディで送信

```perl
my $res = $ua->post('https://example.com/api' => form => {
    username => 'user',
    password => 'pass',
})->result;
```

### 2.2 HTML解析の手法（Mojo::DOMの使い方）

Mojo::DOMはCSSセレクタでHTML要素を抽出できる強力なライブラリ。

**基本パターン**:

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
my $dom = $ua->get('https://example.com')->result->dom;

# 単一要素取得
my $title = $dom->at('title')->text;

# 複数要素取得
$dom->find('a')->each(sub {
    my $link = shift;
    say $link->attr('href');
});
```

### 2.3 CSSセレクタでの要素抽出

| セレクタ | 説明 | 例 |
|----------|------|-----|
| `tagname` | タグ名で選択 | `$dom->find('div')` |
| `.classname` | クラス名で選択 | `$dom->find('.article')` |
| `#idname` | IDで選択 | `$dom->at('#main')` |
| `[attr]` | 属性で選択 | `$dom->find('a[href]')` |
| `[attr*="value"]` | 属性値の部分一致 | `$dom->find('a[href*="example"]')` |
| `parent > child` | 直接の子要素 | `$dom->find('ul > li')` |
| `ancestor descendant` | 子孫要素 | `$dom->find('div p')` |
| `:nth-child(n)` | n番目の子要素 | `$dom->find('li:nth-child(2)')` |
| `:not(selector)` | 否定 | `$dom->find('div:not(.ad)')` |

**出典**:
- https://docs.mojolicious.org/Mojo/DOM/CSS (信頼度: 高)
- https://metacpan.org/pod/Mojo::DOM::CSS (信頼度: 高)

---

## 3. 実践的なコード例

### 3.1 シンプルなGETリクエスト

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# GETリクエストを送信
my $tx = $ua->get('https://example.com/');
my $res = $tx->result;

# レスポンスの確認
if ($res->is_success) {
    print $res->body;
} else {
    warn "Request failed: " . $res->message;
}
```

### 3.2 フォーム送信（POST）

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# POSTでフォームデータを送信
my $tx = $ua->post('https://example.com/login' => form => {
    username => 'myuser',
    password => 'mypassword',
});

my $res = $tx->result;

if ($res->is_success) {
    print "Login successful!\n";
    # 認証後のページにアクセス
    my $protected = $ua->get('https://example.com/dashboard')->result;
    print $protected->dom->at('h1')->text;
}
```

### 3.3 Cookie/セッション管理

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# Cookie jarは自動的に管理される
# ログインしてセッションを確立
$ua->post('https://example.com/login' => form => {
    username => 'user',
    password => 'pass',
});

# 同じUAインスタンスを使えばCookieが保持される
my $res = $ua->get('https://example.com/members')->result;

# Cookie jarを確認
for my $cookie ($ua->cookie_jar->all) {
    say "Cookie: " . $cookie->name . "=" . $cookie->value;
}
```

### 3.4 エラーハンドリング

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::UserAgent;
use Try::Tiny;

my $ua = Mojo::UserAgent->new(
    max_redirects => 5,
    request_timeout => 10,
);

sub scrape_with_retry {
    my ($url, $max_retries) = @_;
    $max_retries //= 3;
    
    for my $attempt (1..$max_retries) {
        try {
            my $tx = $ua->get($url);
            
            if (my $err = $tx->error) {
                die "HTTP error: $err->{code} $err->{message}\n" if $err->{code};
                die "Connection error: $err->{message}\n";
            }
            
            return $tx->result->dom;
        } catch {
            warn "Attempt $attempt failed: $_";
            if ($attempt < $max_retries) {
                sleep 2 ** $attempt;  # 指数バックオフ
            }
        };
    }
    
    die "Failed to scrape $url after $max_retries attempts\n";
}

my $dom = scrape_with_retry('https://example.com/');
```

---

## 4. スクレイピングのベストプラクティスと注意点

### 4.1 robots.txtの確認

```perl
use Mojo::UserAgent;
use WWW::RobotRules;

my $ua = Mojo::UserAgent->new;
my $rules = WWW::RobotRules->new('MyBot/1.0');

# robots.txtを取得して解析
my $robots_url = 'https://example.com/robots.txt';
my $robots_txt = $ua->get($robots_url)->result->body;
$rules->parse($robots_url, $robots_txt);

# スクレイピング可能かチェック
my $target_url = 'https://example.com/products';
if ($rules->allowed($target_url)) {
    print "Allowed to scrape $target_url\n";
} else {
    print "Not allowed to scrape $target_url\n";
}
```

### 4.2 適切なリクエスト間隔

```perl
# サーバーに負荷をかけないよう間隔を空ける
sub polite_get {
    my ($ua, $url) = @_;
    sleep 2;  # 2秒待機
    return $ua->get($url);
}

# 並行リクエスト数を制限
my $ua = Mojo::UserAgent->new(max_connections => 4);
```

### 4.3 User-Agentの設定

```perl
my $ua = Mojo::UserAgent->new;

# ボット名とコンタクト情報を設定（推奨）
$ua->transactor->name('MyBot/1.0 (contact@example.com)');
```

### 4.4 法的・倫理的考慮事項

| 項目 | 説明 |
|------|------|
| **robots.txtの遵守** | 法的拘束力はないが、無視すると悪意とみなされる可能性がある |
| **利用規約の確認** | スクレイピングを禁止するサイトも多い |
| **著作権** | 取得したデータの再配布には注意が必要 |
| **個人情報保護法** | GDPR、個人情報保護法に抵触しないよう注意 |
| **サーバー負荷** | 過度なリクエストはDoS攻撃とみなされる可能性 |
| **APIの優先利用** | 公式APIがあれば、そちらを優先すべき |

**出典**:
- https://blog.froxy.com/en/ethical-web-scraping (信頼度: 中)
- https://www.roborabbit.com/blog/is-web-scraping-legal-5-best-practices-for-ethical-web-scraping-in-2024/ (信頼度: 中)
- https://www.grepsr.com/blog/legal-ethical-web-page-scraping/ (信頼度: 中)

---

## 5. 競合記事の分析

### 5.1 調査した競合記事

#### 日本語記事

| 記事タイトル/トピック | URL | 特徴 |
|----------------------|-----|------|
| Webスクレイピング入門 | https://aiacademy.jp/media/?p=341 | Python中心だが基本概念を網羅 |
| スクレイピングとは | https://qiita.com/Octoparse_Japan/items/3a766a5615d82674b873 | 初心者向け、ツール紹介が中心 |
| 初心者向けスクレイピング | https://www.shtockdata.com/blog/detail28.php | 基本概念の解説 |

#### 英語記事

| 記事タイトル/トピック | URL | 特徴 |
|----------------------|-----|------|
| Web Scraping with Perl Guide | https://brightdata.com/blog/web-data/web-scraping-with-perl | Perl全般のスクレイピング解説 |
| Building a Proxy Rotator with Perl and Mojo | https://proxiesapi.com/articles/building-a-simple-proxy-rotator-with-perl-and-mojo | 実践的なプロキシ設定 |

### 5.2 競合との差別化ポイント

- **Mojo::UserAgentに特化**: 多くの記事はLWPやPython中心で、Mojo::UserAgent特化は少ない
- **日本語での詳細解説**: 公式ドキュメントは英語なので、日本語での詳しい解説に価値がある
- **初心者向け段階的解説**: 基本から実践まで一貫した流れで解説
- **最新版の情報**: 2024-2025年の最新機能（resumable downloads等）に言及

---

## 6. 内部リンク調査

### 6.1 調査コマンド

```bash
grep -ri "perl\|Perl\|mojolicious\|Mojolicious\|Mojo" /content/post
grep -ri "UserAgent\|LWP\|scraping\|スクレイピング\|HTTP" /content/post
```

### 6.2 関連記事一覧（内部リンク候補）

| ファイルパス | 内部リンク | 関連トピック |
|-------------|-----------|--------------|
| `/content/post/2025/12/22/000000.md` | `/2025/12/22/000000/` | PerlでのWebスクレイピング - Web::Scraper と Mojo::UserAgent（直接関連） |
| `/content/post/2025/12/04/000000.md` | `/2025/12/04/000000/` | Mojolicious入門（基礎知識として参照） |
| `/content/post/2025/12/14/183305.md` | `/2025/12/14/183305/` | Perl WebSocket入門：Mojoliciousで作る3つの実践アプリ（発展的内容） |
| `/content/post/2023/03/21/132630.md` | `/2023/03/21/132630/` | YAPC::Kyoto 2023（Perlコミュニティ関連） |

### 6.3 推奨内部リンク

1. **必須リンク**: `/2025/12/22/000000/` - 同じスクレイピングトピックの記事
2. **推奨リンク**: `/2025/12/04/000000/` - Mojolicious基礎の参照として
3. **発展リンク**: `/2025/12/14/183305/` - WebSocket等のリアルタイム通信への発展

---

## 7. 参照すべき重要リソース

### 7.1 公式ドキュメント

| リソース | URL | 説明 |
|----------|-----|------|
| Mojolicious公式サイト | https://mojolicious.org/ | フレームワーク公式 |
| Mojo::UserAgent ドキュメント | https://docs.mojolicious.org/Mojo/UserAgent | UserAgent API |
| Mojo::DOM ドキュメント | https://docs.mojolicious.org/Mojo/DOM | DOM操作API |
| Mojo::DOM::CSS ドキュメント | https://docs.mojolicious.org/Mojo/DOM/CSS | CSSセレクタ仕様 |

### 7.2 MetaCPAN

| リソース | URL | 説明 |
|----------|-----|------|
| Mojolicious | https://metacpan.org/pod/Mojolicious | メインディストリビューション |
| Mojo::UserAgent | https://metacpan.org/pod/Mojo::UserAgent | UserAgentモジュール |
| WWW::RobotRules | https://metacpan.org/pod/WWW::RobotRules | robots.txt解析 |
| Try::Tiny | https://metacpan.org/pod/Try::Tiny | エラーハンドリング |

### 7.3 チュートリアル・参考記事

| リソース | URL | 説明 |
|----------|-----|------|
| Mojolicious Tutorial | https://docs.mojolicious.org/Mojolicious/Guides/Tutorial | 公式チュートリアル |
| Mojolicious Cookbook | https://docs.mojolicious.org/Mojolicious/Guides/Cookbook | 実践的レシピ集 |
| Web Scraping with Perl | https://brightdata.com/blog/web-data/web-scraping-with-perl | Perlスクレイピング全般 |

---

## 8. 発見と結論

### 8.1 主要な発見

1. **Mojo::UserAgentは最もモダンなPerl HTTPクライアント**
   - 非同期処理、Promise対応、WebSocket、DOM解析が統合されている
   - 2024-2025年も活発に開発が続いている

2. **スクレイピングに最適な組み合わせ**
   - Mojo::UserAgent + Mojo::DOM でHTTP取得とHTML解析を一貫して行える
   - CSSセレクタで直感的に要素抽出が可能

3. **法的・倫理的配慮が必須**
   - robots.txt、利用規約、リクエスト間隔に注意
   - 公式APIがあればAPIを優先

4. **既存記事との差別化可能**
   - Mojo::UserAgentに特化した日本語記事は少ない
   - 内部リンクで関連コンテンツと連携可能

### 8.2 記事構成案（仮）

1. **はじめに**: スクレイピングとは、なぜMojo::UserAgentか
2. **準備**: Mojoliciousのインストール
3. **基本**: GETリクエスト、レスポンス確認
4. **HTML解析**: Mojo::DOMとCSSセレクタ
5. **実践**: フォーム送信、Cookie管理、エラーハンドリング
6. **マナー**: robots.txt、リクエスト間隔、User-Agent設定
7. **応用**: 非同期リクエスト、ページネーション対応
8. **まとめ**: 次のステップ、参考リンク

### 8.3 信頼度サマリー

| 情報カテゴリ | 信頼度 | 根拠 |
|-------------|--------|------|
| Mojo::UserAgent機能・API | 高 | 公式ドキュメント、MetaCPAN |
| スクレイピング基本概念 | 高 | 技術的事実、多数の一次情報 |
| 法的考慮事項 | 中 | 地域・ケースにより異なる、専門家確認推奨 |
| 競合記事分析 | 中 | 調査時点での情報、変動あり |
| 最新バージョン情報 | 高 | MetaCPAN Changes履歴 |

---

## 付録: 調査で使用したコマンド

```bash
# 内部リンク調査
grep -ri "perl\|Perl\|mojolicious\|Mojolicious\|Mojo" /content/post
grep -ri "UserAgent\|LWP\|scraping\|スクレイピング\|HTTP" /content/post

# ディレクトリ確認
ls /content/warehouse/
```

---

## 更新履歴

- 2025-12-30: 初版作成
