# 調査レポート: Mojo::UserAgentでスクレイピング入門記事

## 調査概要

- **調査日**: 2025-12-28
- **調査目的**: Perlの初心者向けに、Mojo::UserAgentを使ったウェブスクレイピングの入門記事を作成するための情報収集
- **対象読者**: 基本的なプログラミングの知識はある初心者、Perlでウェブサイトのスクレイピングをして、情報を取得したい人

---

## 1. Mojo::UserAgentの基本情報

### 1.1 最新バージョンとドキュメント

- **公式ドキュメント**: https://docs.mojolicious.org/Mojo/UserAgent
- **MetaCPAN**: https://metacpan.org/pod/Mojo::UserAgent
- **Ubuntu Manpage**: https://manpages.ubuntu.com/manpages/bionic/man3/Mojo::UserAgent.3pm.html

### 1.2 主な機能と特徴

**コア機能**:
- **ノンブロッキングI/O**: 非同期HTTP/WebSocketをコールバックとPromiseでサポート
- **WebSocketサポート**: リアルタイムメッセージングとストリーミング用のネイティブWebSocketクライアント
- **モダンなプロトコル**: IPv6, TLS, SNI, IDNA対応
- **プロキシサポート**: HTTP、SOCKS5プロキシ、Tor対応
- **UNIXドメインソケット**: TCP/IP以外にUNIXドメインソケットでも通信可能
- **豊富なHTTPメソッド**: GET, POST, PUT, DELETE等、ブロッキング版と非ブロッキング版の両方を提供
- **コンテンツタイプ**: Form, JSON, Multipart, Gzip等の自動エンコード/デコード
- **Cookie & リダイレクト**: Cookie管理と設定可能な最大リダイレクト数のサポート

**最近の改善点**:
- **Mojo::UserAgent::Role::TotalTimeout**: CPANで最近追加されたロール。リダイレクトを含めた全体のタイムアウト設定が可能（トランザクション全体の時間管理に有用）
- **コネクションプーリングとKeep-Alive**: 多数の短命リクエストが発生する環境でのパフォーマンス最大化
- **高度なプロキシ設定**: より詳細なネットワーク要件に対応

**参考URL**:
- https://docs.mojolicious.org/Mojo/UserAgent
- https://metacpan.org/pod/Mojo::UserAgent
- https://www.perl.com/article/what-s-new-on-cpan---november-2024/ (最新情報)

**信頼性評価**: ★★★★★（公式ドキュメント、活発なメンテナンス）

---

### 1.3 インストール方法

```bash
# cpanを使用
cpan Mojolicious

# cpanmを使用
cpanm Mojolicious
```

Mojoliciousをインストールすると、Mojo::UserAgentも含まれます。

---

### 1.4 他のスクレイピングライブラリとの比較

#### LWP::UserAgent
**特徴**:
- Perlの基盤的HTTPクライアント（libwww-perlスイートの一部）
- 同期処理のみ
- シンプルなHTTPリクエスト/レスポンスサイクルに最適
- 成熟していて信頼性が高い
- HTML::TreeBuilderなどと組み合わせて使用

**長所**:
- 成熟、実戦テスト済み、信頼性が高い
- シンプルなAPI、基本的なスクレイピングに簡単
- 静的HTMLの解析と組み合わせて利用可能

**短所**:
- JavaScript重視の動的コンテンツには制限あり
- 同期処理：非ブロッキング/非同期リクエストの組み込みサポートなし
- 高レベル自動化機能（フォーム入力、リンク追跡）がない

**典型的な使用例**: HTTPリクエストのみが必要な単純なスクレイパー、静的HTMLの解析

#### WWW::Mechanize
**特徴**:
- LWP::UserAgent上に構築
- ブラウザライクな自動化を追加
- フォーム、リンクのナビゲーション、Cookie管理、セッションの管理が可能
- シンプルなブラウザセッションをPerl内でエミュレート

**長所**:
- フォーム送信、リンクナビゲーション、セッション管理のための高レベル機能
- ログイン、ナビゲーション、マルチステップアクションが必要なサイトに最適

**短所**:
- LWP::UserAgentと同様、同期/ブロッキング処理
- JavaScript重視のページには不向き（JSは実行しない）
- LWP::UserAgentより依存関係がやや重い

**典型的な使用例**: ブラウザタスクの自動化、フォーム送信、マルチステップWebワークフロー

#### Mojo::UserAgent
**特徴**:
- Mojoliciousエコシステムの一部
- ブロッキングと非ブロッキング（非同期）リクエストの両方をサポート
- WebSocket、コネクションプーリング、Promiseサポート
- CSSセレクタを使った組み込みHTML/XML DOMパーサー（Mojo::DOM）
- HTTP/SOCKS5プロキシなど高度な機能

**長所**:
- 高並行スクレイピングのための非同期（async）サポート
- CSSセレクタ付き組み込みHTML/XML DOMパーサー
- 動的リクエストをスムーズに処理。モダンなWeb APIに最適
- リッチなイベントループとPromises APIで高度なワークフロー対応
- セキュアな接続、プロキシなどのサポート

**短所**:
- LWP::UserAgentと比較するとやや学習曲線が急
- 非常にシンプルなスクリプトにはオーバーキルの可能性

**典型的な使用例**: APIのスクレイピング、WebSocketの処理、並行スクレイピングタスク、動的コンテンツの解析

#### まとめ
- **LWP::UserAgent**: シンプルさと信頼性が重要な基本的で堅牢なHTTPリクエストに使用
- **Mojo::UserAgent**: 非同期操作、高度なWeb機能が必要な場合、モダン/動的サイトやAPIのスクレイピングに使用
- **WWW::Mechanize**: スクレイピングシナリオがユーザーのブラウザとのインタラクション（リンク、フォーム、セッション）をエミュレートする場合に使用

**参考URL**:
- https://scrape.do/blog/web-scraping-in-perl/
- https://webscrapingsite.com/blog/web-scraping-with-perl-a-comprehensive-guide/
- https://brightdata.com/blog/web-data/web-scraping-with-perl

**信頼性評価**: ★★★★★（複数の信頼できるソースからの情報）

---

## 2. スクレイピングの基礎知識

### 2.1 HTMLパース方法（Mojo::DOMの使い方）

Mojo::DOMは、Mojoliciousツールキットの一部で、CSSセレクタをサポートする軽量HTML/XML DOMパーサーです。

**基本的な使い方**:

```perl
use Mojo::UserAgent;
use Mojo::DOM;

my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://example.com')->result;

# DOM解析
my $dom = $res->dom;  # または Mojo::DOM->new($res->body)

# CSSセレクタで要素を取得
my $first_p = $dom->at('p#b');  # 最初の<p id="b">を取得
print $first_p->text, "\n";

# すべてのマッチする要素を取得
for my $p ($dom->find('p')->each) {
    print $p->text, "\n";
}

# 属性を持つすべての要素を取得
for my $e ($dom->find('[id]')->each) {
    print $e->attr('id'), ': ', $e->text, "\n";
}
```

**テーブルのスクレイピング例**:

```perl
my $table = $dom->find('table.wikitable.sortable')->[0];
foreach my $row ($table->find('tr')->slice(1)->each) {  # ヘッダーをスキップ
    my ($name, $group, $local_name, $img) = 
        map $_->text, $row->find('td, th')->each;
    # 各データを処理
}
```

**参考URL**:
- https://mojolicious.org/perldoc/Mojo/DOM
- https://metacpan.org/pod/Mojo::DOM
- https://proxiesapi.com/articles/downloading-images-from-a-website-with-perl-and-mojo-dom

**信頼性評価**: ★★★★★（公式ドキュメント）

---

### 2.2 CSSセレクタの基本

Mojo::DOMはほとんどのCSS3セレクタをサポートしています：

- **クラス**: `.classname`
- **ID**: `#id`
- **属性**: `[attr="value"]`
- **子孫**: `div p`
- **否定**: `:not(p)`
- **組み合わせ**: `table.wikitable.sortable`

**Tips**:
- `at`は最初のマッチを返す
- `find`はすべてのマッチを返す
- `each`, `map`, `slice`などのイテレータメソッドと、`attr`, `text`, `all_text`などのメソッドで抽出が簡単
- HTMLの場合、CSSセレクタはデフォルトで大文字小文字を区別しない。XMLモードでは大文字小文字が重要

**参考URL**:
- https://www.scrapingbee.com/blog/using-css-selectors-for-web-scraping/

**信頼性評価**: ★★★★☆（信頼できるスクレイピング情報源）

---

### 2.3 User-Agentの設定

User-Agentを設定することで、スクレイパーを正直に識別できます：

```perl
my $ua = Mojo::UserAgent->new;
$ua->agent('YourBotName/1.0 (+https://yourwebsite.com/bot-info)');

# またはリクエストごとに設定
my $res = $ua->get(
    'https://example.com',
    {'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) Chrome/123.0.0.0'}
)->result;
```

**ベストプラクティス**:
- 通常のブラウザのふりをしたい場合でも、ボット実行時は正直に識別する
- ヘッダーを設定することで、リクエストがより正規に見え、成功率が向上
- シンプルなアンチボットメカニズムをバイパスできる

**参考URL**:
- https://www.scrapingdog.com/blog/user-agent-in-web-scraping/
- https://hasdata.com/blog/user-agents-for-web-scraping
- https://www.zenrows.com/blog/user-agent-web-scraping

**信頼性評価**: ★★★★☆（実践的なスクレイピングガイド）

---

### 2.4 エラーハンドリング

**基本的なエラーハンドリング**:

```perl
my $res = $ua->get('https://example.com')->result;

if ($res->is_success) {
    print "成功!\n";
    print $res->body;
} elsif ($res->is_error) {
    warn "エラー: " . $res->message . "\n";
} else {
    warn "その他のレスポンス: HTTP " . $res->code . "\n";
}
```

**接続エラーの処理**:

```perl
my $success = eval { $tx->result->is_success };
unless ($success) {
    warn "リクエスト失敗: $@";
}
```

**トランザクションエラーの確認**:

```perl
my $tx = $ua->get('https://example.com');
if (my $err = $tx->error) {
    die "$err->{code} response: $err->{message}" if $err->{code};
    die "Connection error: $err->{message}";
}
```

**参考URL**:
- https://docs.mojolicious.org/Mojo/UserAgent
- https://stackoverflow.com/questions/59958976/how-can-i-get-access-to-json-in-a-mojouseragent-response
- https://github.polettix.it/ETOOBUSY/2021/02/22/mojo-useragent-intro-notes/

**信頼性評価**: ★★★★★（公式ドキュメントとコミュニティソース）

---

### 2.5 リトライ戦略

**シンプルなリトライループ**:

```perl
my $max_retries = 3;
my $res;

for my $attempt (1..$max_retries) {
    $res = $ua->get('https://example.com')->result;
    last if $res->is_success;
    
    warn "Attempt $attempt failed: " . $res->message;
    sleep 2;  # バックオフ
}

die "All attempts failed" unless $res->is_success;
```

**エクスポネンシャルバックオフ**:

```perl
use Time::HiRes qw(usleep);

my $max_retries = 5;
my $base_delay = 1;  # 秒

for my $attempt (1..$max_retries) {
    my $res = $ua->get('https://example.com')->result;
    
    if ($res->is_success) {
        # 処理を続行
        last;
    }
    
    if ($res->code == 429) {  # Too Many Requests
        my $delay = $base_delay * (2 ** ($attempt - 1));
        warn "Rate limited. Waiting ${delay}s before retry $attempt/$max_retries";
        sleep $delay;
    } elsif ($res->is_error) {
        warn "Error on attempt $attempt: " . $res->message;
        sleep $base_delay;
    }
}
```

**信頼性評価**: ★★★★☆（一般的なベストプラクティス）

---

## 3. 実践的なコード例

### 3.1 シンプルなGETリクエスト

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://jsonplaceholder.typicode.com/posts/1')->result;

if ($res->is_success) {
    print "Response: " . $res->body . "\n";
} elsif ($res->is_error) {
    warn "Error: " . $res->message . "\n";
}
```

**JSONレスポンスの処理**:

```perl
if ($res->is_success) {
    my $json = $res->json;
    print "Title: " . $json->{title} . "\n";
    print "Body: " . $json->{body} . "\n";
}
```

---

### 3.2 HTMLの要素抽出

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
$ua->agent('PerlScraper/1.0');

my $res = $ua->get('https://blogs.perl.org')->result;
die "Request failed!" unless $res->is_success;

# 見出しを抽出
for my $headline ($res->dom->find('h2 > a')->map('text')->each) {
    say $headline;
}
```

**実世界の例：Wikipediaから犬種の画像をスクレイピング**:

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
$ua->agent('PerlScraper');

my $res = $ua->get('https://commons.wikimedia.org/wiki/List_of_dog_breeds')->result;
my $dom = $res->dom;

my $table = $dom->at('table.wikitable.sortable');
for my $row ($table->find('tr')->slice(1)->each) {
    my @cols = $row->find('td')->each;
    next unless @cols;
    
    my $name = $cols[0]->text;
    my $img = $cols[1]->at('img');
    my $img_url = $img ? $img->attr('src') : 'N/A';
    
    print "$name: $img_url\n";
}
```

---

### 3.3 複数ページのクローリング

```perl
use Mojo::UserAgent;
use Time::HiRes qw(usleep);

my $ua = Mojo::UserAgent->new;
my @urls = (
    'https://example.com/page1',
    'https://example.com/page2',
    'https://example.com/page3',
);

foreach my $url (@urls) {
    my $res = $ua->get($url)->result;
    
    if ($res->is_success) {
        # データを抽出
        my $title = $res->dom->at('title')->text;
        print "Page: $title\n";
        
        # 各ページのリンクを抽出
        for my $link ($res->dom->find('a[href]')->each) {
            print "  Link: " . $link->attr('href') . "\n";
        }
    }
    
    # レート制限を尊重（2秒待機）
    usleep(2_000_000);
}
```

---

### 3.4 JSONレスポンスの処理

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# GET JSON API
my $res = $ua->get('https://api.example.com/data.json')->result;
my $data = $res->json;

print "Name: " . $data->{name} . "\n";

# POST JSON
my $tx = $ua->post('https://jsonplaceholder.typicode.com/posts' =>
    json => {title => 'foo', body => 'bar', userId => 1}
);

my $result = $tx->result;
if ($result->is_success) {
    print "Created ID: " . $result->json->{id} . "\n";
} else {
    warn "POST Error: " . $result->message . "\n";
}
```

**参考URL**:
- https://docs.mojolicious.org/Mojo/UserAgent
- https://manpages.ubuntu.com/manpages/bionic/man3/Mojo::UserAgent.3pm.html
- https://proxiesapi.com/articles/downloading-images-from-a-website-with-perl-and-mojo-dom

**信頼性評価**: ★★★★★（公式ドキュメントと実証済みの例）

---

## 4. ベストプラクティスと注意事項

### 4.1 robots.txtの尊重

**重要性**:
- スクレイピングの前に必ず`robots.txt`ファイル（通常`https://example.com/robots.txt`）をチェック
- ボットとウェブスクレイパーのためにどのパスが許可/禁止されているかを示す
- `robots.txt`を無視すると、IPバン、ブロック、法的結果（Computer Fraud and Abuse Act等）につながる可能性

**基本的な確認方法**:

```perl
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my $robots_url = 'https://example.com/robots.txt';
my $response = $ua->get($robots_url);

if ($response->is_success) {
    my @lines = split("\n", $response->decoded_content);
    foreach (@lines) {
        # Disallow行を解析してロジックを実装
        print $_;
    }
}
```

**注意**:
- より堅牢な`robots.txt`解析には、専用のパーサーを使用または実装する必要がある
- `robots.txt`のルールは時間とともに変更される可能性があるため、定期的に再チェックする

**参考URL**:
- https://www.promptcloud.com/blog/how-to-read-and-respect-robots-file/
- https://expertbeacon.com/the-ultimate-guide-to-using-robots-txt-for-web-scraping/
- https://www.scrapeless.com/en/blog/robots-txt-for-web-scraping

**信頼性評価**: ★★★★★（業界標準のベストプラクティス）

---

### 4.2 レート制限・マナー

**基本原則**:
- サーバーの過負荷を避けるため、各リクエスト間に遅延を実装
- 一般的には1-2秒の遅延が良いベースライン
- `robots.txt`の`Crawl-delay`ディレクティブがある場合は、それを尊重する
- 動的レート制限（サイトが遅い場合や429エラーを返す場合は遅延を増やす）を実装する

**実装例**:

```perl
use Time::HiRes qw(usleep);

foreach my $url (@urls) {
    # スクレイピング処理
    my $res = $ua->get($url)->result;
    # ...
    
    # 2秒待機
    usleep(2_000_000);
}
```

**高度なレート制限**:

```perl
my $delay = 2;  # 秒
my $max_delay = 10;

foreach my $url (@urls) {
    my $res = $ua->get($url)->result;
    
    if ($res->code == 429) {  # Too Many Requests
        $delay = min($delay * 2, $max_delay);
        warn "Rate limited. Increasing delay to ${delay}s";
    } elsif ($res->is_success) {
        # 成功したので遅延をリセット
        $delay = 2;
    }
    
    # 処理...
    
    usleep($delay * 1_000_000);
}
```

**参考URL**:
- https://peerdh.com/blogs/programming-insights/implementing-rate-limiting-strategies-for-web-scraping-in-perl
- https://injectapi.com/blog/web-scraping-best-practices-2025

**信頼性評価**: ★★★★★（エシカルスクレイピングの基本）

---

### 4.3 エラーハンドリング

**包括的なエラーハンドリング**:

```perl
my $tx = $ua->get('https://example.com');

# トランザクションエラーを確認
if (my $err = $tx->error) {
    if ($err->{code}) {
        die "$err->{code} response: $err->{message}";
    } else {
        die "Connection error: $err->{message}";
    }
}

# レスポンスステータスを確認
my $res = $tx->result;
if ($res->is_success) {
    # 処理を続行
} elsif ($res->code == 404) {
    warn "Page not found";
} elsif ($res->code == 429) {
    warn "Rate limited";
    # バックオフロジックを実装
} elsif ($res->code >= 500) {
    warn "Server error: " . $res->code;
    # リトライロジックを実装
}
```

**グレースフルエラーハンドリング**:
- HTTP 429（Too Many Requests）レスポンスを予測し、適切に処理
- バックオフ戦略とリトライを実装（許可された場合のみ）
- すべてのクローリングアクティビティをログに記録

**参考URL**:
- https://injectapi.com/blog/web-scraping-best-practices-2025

**信頼性評価**: ★★★★★（業界標準）

---

### 4.4 文字エンコーディング処理

Mojo::UserAgentは文字エンコーディングを自動的に処理しますが、注意が必要な場合があります：

```perl
# デコードされたコンテンツを取得
my $text = $res->body;  # 自動的にデコード

# DOMを使用する場合は自動的に処理される
my $dom = $res->dom;
my $content = $dom->at('p')->text;  # 自動的にデコード

# 手動でエンコーディングを指定する必要がある場合
use Encode qw(decode);
my $decoded = decode('UTF-8', $res->body);
```

**Tips**:
- Mojo::UserAgentはContent-Typeヘッダーからエンコーディングを自動検出
- 日本語サイトの場合、UTF-8、Shift_JIS、EUC-JPなどに注意
- 問題がある場合は、`charset`を明示的に処理

**信頼性評価**: ★★★★☆（実践的な知識）

---

## 5. 参考リソース

### 5.1 公式ドキュメント

1. **Mojo::UserAgent 公式ドキュメント**
   - URL: https://docs.mojolicious.org/Mojo/UserAgent
   - 内容: 完全なAPIリファレンス、多数の使用例、属性とメソッドの説明
   - 信頼性: ★★★★★

2. **Mojo::DOM 公式ドキュメント**
   - URL: https://mojolicious.org/perldoc/Mojo/DOM
   - 内容: CSSセレクタ、DOM操作、HTML/XML解析
   - 信頼性: ★★★★★

3. **MetaCPAN - Mojo::UserAgent**
   - URL: https://metacpan.org/pod/Mojo::UserAgent
   - 内容: 最新モジュールバージョン、関連モジュールへのリンク
   - 信頼性: ★★★★★

4. **Mojo::UserAgent::Transactor**
   - URL: https://docs.mojolicious.org/Mojo/UserAgent/Transactor
   - 内容: POST JSON、フォームデータの送信方法
   - 信頼性: ★★★★★

### 5.2 チュートリアルと記事

1. **Mojo::UserAgent introductory notes**
   - URL: https://github.polettix.it/ETOOBUSY/2021/02/22/mojo-useragent-intro-notes/
   - 内容: 初心者向けの実践的な導入ノート
   - 信頼性: ★★★★☆

2. **Downloading Images from a Website with Perl and Mojo::DOM**
   - URL: https://proxiesapi.com/articles/downloading-images-from-a-website-with-perl-and-mojo-dom
   - 内容: 実世界のスクレイピング例（Wikipedia犬種画像）
   - 信頼性: ★★★★☆

3. **Web Scraping in Perl | Scrape.do**
   - URL: https://scrape.do/blog/web-scraping-in-perl/
   - 内容: Perlでのウェブスクレイピングの包括的ガイド
   - 信頼性: ★★★★☆

4. **Web Scraping with Perl Guide: Methods and Challenges**
   - URL: https://brightdata.com/blog/web-data/web-scraping-with-perl
   - 内容: 方法と課題の詳細なガイド
   - 信頼性: ★★★★☆

5. **Web Scraping With Perl: A Comprehensive Guide**
   - URL: https://webscrapingsite.com/blog/web-scraping-with-perl-a-comprehensive-guide/
   - 内容: LWP::UserAgent、WWW::Mechanizeとの比較を含む
   - 信頼性: ★★★★☆

### 5.3 ベストプラクティスとエシカルスクレイピング

1. **Ethical Web Scraping: Principles and Practices**
   - URL: https://www.datacamp.com/blog/ethical-web-scraping
   - 内容: エシカルスクレイピングの原則と実践
   - 信頼性: ★★★★★

2. **Web Scraping Best Practices 2025**
   - URL: https://injectapi.com/blog/web-scraping-best-practices-2025
   - 内容: 2025年の最新ベストプラクティス
   - 信頼性: ★★★★☆

3. **The Ultimate Guide to Using Robots.txt for Web Scraping**
   - URL: https://expertbeacon.com/the-ultimate-guide-to-using-robots-txt-for-web-scraping/
   - 内容: robots.txtの詳細なガイド
   - 信頼性: ★★★★☆

4. **Implementing Rate Limiting Strategies For Web Scraping In Perl**
   - URL: https://peerdh.com/blogs/programming-insights/implementing-rate-limiting-strategies-for-web-scraping-in-perl
   - 内容: Perlでのレート制限戦略
   - 信頼性: ★★★★☆

### 5.4 書籍

1. **Modern Perl (Fourth Edition)**
   - 著者: chromatic (Shane Warden)
   - 出版社: Pragmatic Bookshelf
   - 出版年: 2015
   - ISBN-13: 9781680500882
   - ASIN: 1680500880
   - 内容: モダンなPerl5.22対応、Moose、Mojoliciousなどのモジュール、ベストプラクティス
   - 購入先: https://www.amazon.com/Modern-Perl-chromatic/dp/1680500880
   - 無料版: https://modernperlbooks.com/books/modern_perl_2016
   - 信頼性: ★★★★★
   - 初心者への推奨度: ★★★★★

**注記**: Modern PerlはMojoliciousを含むモダンなPerlウェブフレームワークとCPANモジュールの使用方法をカバーしており、スクレイピングと解析の基礎を学ぶのに最適

### 5.5 GitHubリポジトリと実例

1. **Mojolicious公式リポジトリ**
   - URL: https://github.com/mojolicious/mojo
   - 内容: ソースコード、issue、examples
   - 信頼性: ★★★★★

2. **Awesome-Web-Scraping (Perl section)**
   - URL: https://github.com/luminati-io/Awesome-Web-Scraping/blob/main/perl.md
   - 内容: Perlウェブスクレイピングツールとリソースのキュレーションリスト
   - 信頼性: ★★★★☆

### 5.6 Stack Overflow / コミュニティ

1. **How can I get access to JSON in a Mojo::UserAgent response?**
   - URL: https://stackoverflow.com/questions/59958976/how-can-i-get-access-to-json-in-a-mojouseragent-response
   - 内容: JSONレスポンスの処理方法
   - 信頼性: ★★★★☆

### 5.7 最新情報

1. **What's new on CPAN - November 2024**
   - URL: https://www.perl.com/article/what-s-new-on-cpan---november-2024/
   - 内容: CPANの最新追加モジュール（Mojo::UserAgent::Role::TotalTimeout等）
   - 信頼性: ★★★★★

---

## 6. 内部リンク調査

### 6.1 Perl関連記事（タグ: perl）

リポジトリ内には多数のPerl関連記事が存在しています（grep結果：400件以上）。

**主な関連記事**:

1. **/content/post/2020/09/09/084205.md**
   - タイトル: 何か書こうとしていた
   - タグ: heroku
   - 内容: Mojoliciousのバージョン情報（v8.34）を含む
   - 関連性: ★★★☆☆

2. **/content/post/2015/02/02/075435.md**
   - タイトル: Mojolicious::Liteでハローワールド
   - タグ: mojolicious, perl, perl-entrance
   - 内容: Mojolicious::Liteの入門記事
   - 関連性: ★★★★★（同じフレームワークの入門記事）

3. **/content/post/2018/06/12/110204.md**
   - タイトル: 以前は動いていた Dockerfile で permission denied が出るようになった話
   - タグ: perl, docker
   - 内容: PerlとDockerの組み合わせ
   - 関連性: ★★★☆☆

### 6.2 関連トピック

**web-scraping関連**:
- grep結果からweb-scrapingタグを持つ記事を確認したが、明示的なタグは少ない
- ただし、多数のMojolicious関連記事が存在

**http-client関連**:
- LWP関連の記事も存在する可能性があるが、主にMojoliciousに関する記事が多い

**mojolicious関連**:
- /content/post/2015/02/02/075435.md（Mojolicious::Liteでハローワールド）
- /content/post/2020/09/09/084205.md（Mojoliciousバージョン情報を含む）
- その他、2015年前後に複数のMojolicious関連記事

### 6.3 推奨内部リンク

記事執筆時に以下の内部リンクを含めることを推奨：

1. Mojolicious::Lite関連の入門記事（既存）
2. Perlの基礎に関する記事（タグ: perl-entrance）
3. 環境構築に関する記事（Dockerなど）

**注記**: 具体的な内部リンクは、記事執筆時にタグ検索を使用して最新の関連記事を見つけることを推奨

---

## 7. 技術的な正確性を担保するための重要なポイント

### 7.1 バージョン情報

- **Mojolicious**: 継続的に更新されているため、記事執筆時に最新の安定バージョンを確認する
- **Perl**: Perl 5.22以降を対象とする（Modern Perlの対象バージョン）
- **依存モジュール**: 特になし（Mojoliciousに含まれる）

### 7.2 検証が必要なコード例

すべてのコード例は以下で検証することを推奨：

1. **基本的なGETリクエスト**: https://jsonplaceholder.typicode.com/ （テスト用API）
2. **DOM解析**: https://blogs.perl.org/ または他の公開ブログ
3. **JSONレスポンス**: https://jsonplaceholder.typicode.com/posts

### 7.3 注意すべき変更点

- **非推奨のメソッド**: 公式ドキュメントで非推奨としてマークされているメソッドを使用しない
- **セキュリティ**: TLS/SSL証明書の検証はデフォルトで有効
- **User-Agent**: デフォルトのUser-Agentは`Mojolicious (Perl)`

### 7.4 初心者が陥りやすい罠

1. **エラーハンドリングの忘れ**: 必ず`is_success`や`is_error`でチェック
2. **レート制限の無視**: 必ず適切な遅延を実装
3. **robots.txtの確認忘れ**: スクレイピング前に必ず確認
4. **文字エンコーディング**: 日本語サイトでは特に注意
5. **無限ループ**: クローリング時のループ検出を実装

---

## 8. 記事構成の推奨

### 8.1 記事の流れ

1. **導入**
   - ウェブスクレイピングとは何か
   - なぜMojo::UserAgentを選ぶのか
   - この記事で学べること

2. **環境準備**
   - Mojoliciousのインストール
   - 動作確認

3. **基礎編**
   - シンプルなGETリクエスト
   - レスポンスの確認
   - エラーハンドリング

4. **DOM解析編**
   - Mojo::DOMの基本
   - CSSセレクタの使い方
   - 実践例

5. **実践編**
   - 複数ページのクローリング
   - JSONの処理
   - 画像のダウンロード

6. **ベストプラクティス編**
   - robots.txtの尊重
   - レート制限
   - エラーハンドリング
   - リトライ戦略

7. **まとめ**
   - 学んだこと
   - 次のステップ
   - 参考リソース

### 8.2 コード例の品質

- **動作確認済み**: すべてのコードは実際に動作することを確認
- **コメント**: 初心者向けに詳細なコメントを付ける
- **段階的**: 簡単な例から複雑な例へと段階的に進める
- **エラーハンドリング**: すべての例にエラーハンドリングを含める

---

## 9. SEO対策キーワード

### 9.1 主要キーワード

- Mojo::UserAgent
- Perl スクレイピング
- Mojolicious スクレイピング
- ウェブスクレイピング Perl
- Mojo::DOM

### 9.2 ロングテールキーワード

- Mojo::UserAgent 使い方
- Perl ウェブスクレイピング 初心者
- Mojolicious 入門
- Perl HTML 解析
- Mojo::UserAgent エラーハンドリング
- Perl robots.txt 確認

### 9.3 関連キーワード

- LWP::UserAgent
- WWW::Mechanize
- HTML::TreeBuilder
- Web::Scraper
- Perl 非同期処理

---

## 10. まとめと次のステップ

### 10.1 調査で得られた重要な知見

1. **Mojo::UserAgentの優位性**: 非同期処理、組み込みDOM解析、モダンな機能が初心者にも使いやすい
2. **豊富なリソース**: 公式ドキュメント、コミュニティ記事、書籍が充実
3. **実践的な例**: 多数の実世界の例が利用可能
4. **エシカルスクレイピング**: robots.txt尊重とレート制限が重要
5. **内部リンク**: Mojolicious関連の既存記事と連携可能

### 10.2 記事執筆時の推奨事項

1. **最新情報の確認**: 執筆時にMojoliciousの最新バージョンを確認
2. **コード検証**: すべてのコード例を実際に実行して検証
3. **スクリーンショット**: 可能であれば実行結果のスクリーンショットを追加
4. **内部リンク**: タグ検索を使用して関連記事を見つけてリンク
5. **外部リンク**: 公式ドキュメントと信頼できるリソースへのリンク

### 10.3 避けるべき事項

1. **古い情報**: 非推奨のメソッドや古いバージョンの情報
2. **違法なスクレイピング**: 利用規約違反やrobots.txt無視の例
3. **複雑すぎる例**: 初心者には複雑すぎるコード
4. **エラーハンドリングなし**: エラーハンドリングのない例
5. **動作未確認のコード**: 検証していないコード例

---

## 調査完了日

2025-12-28

## 調査者メモ

この調査により、Mojo::UserAgentを使ったウェブスクレイピング入門記事の執筆に必要な情報を十分に収集できました。特に以下の点が明確になりました：

1. Mojo::UserAgentは初心者にとって学習曲線が適度で、強力な機能を持つ
2. 公式ドキュメントと実践的な例が豊富に存在する
3. エシカルスクレイピングの重要性を強調する必要がある
4. 既存のMojolicious関連記事との連携が可能
5. Modern Perl書籍が優れた参考資料として利用可能

記事執筆時には、この調査結果を基に、初心者が実際に手を動かしながら学べる実践的な内容を作成することを推奨します。
