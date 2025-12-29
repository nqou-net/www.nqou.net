# 調査ドキュメント: Mojo::UserAgentでスクレイピング入門

## 調査目的

Perlの初心者向けに、Mojo::UserAgentを使ったウェブスクレイピングの入門記事を執筆するための情報収集。読者がMojo::UserAgentの基礎を理解し、実践的なスクレイピングコードを書けるようになることを目指す。

## 実施日

2024年12月29日

---

## 調査結果

### 1. Mojo::UserAgentの基本機能

#### 概要
- **Mojo::UserAgent**は、Mojoliciousフレームワークに含まれるHTTPクライアントモジュール
- 非ブロッキングI/O、HTTP、WebSocketに対応したユーザーエージェント
- HTMLパーサー（Mojo::DOM）が統合されており、jQuery風のCSSセレクタでデータ抽出が可能

#### 主な機能
- GET/POSTリクエストの実行
- JSON/フォームデータの送信・受信
- HTMLのDOM解析（CSSセレクタベース）
- 非同期・並列処理のサポート
- プロキシ、リダイレクト、Cookie、TLS対応
- IPv6、keep-alive、コネクションプーリング、gzip圧縮対応

#### インストール方法
MojoliciousはCPANからインストール可能：
```bash
cpan Mojolicious
# または
cpanm Mojolicious
```

#### 最新バージョンと動作要件
- **最新バージョン**: Mojolicious 9.37（2024年5月時点）
- **必須Perlバージョン**: Perl 5.16以上
- **推奨Perlバージョン**: Perl 5.18以上（5.20以降が望ましい）
- Mojoliciousは「最新の2つの安定したPerlリリース」を公式サポート
- Modern Perlの機能（strict/warnings/utf8、サブルーチン署名など）を活用

#### 参照元URL
- https://mojolicious.org/
- https://metacpan.org/pod/Mojo::UserAgent
- https://docs.mojolicious.org/
- https://en.wikipedia.org/wiki/Mojolicious

---

### 2. スクレイピングのベストプラクティス

#### robots.txtの確認方法
- **重要性**: robots.txtは倫理的ガイドライン。法的拘束力はないが、無視すると禁止措置や法的紛争の可能性
- **確認方法**: サイトのルートディレクトリ（例：example.com/robots.txt）を確認
- **実装**: スクレイピング前にrobots.txtを解析し、Disallowされたパスを回避する
- Perl実装では、URLをDisallowパスと照合し、制限されたリソースをスキップ

#### リクエスト間隔の設定（レート制限）
- **目的**: サーバーへの負荷を軽減し、DoS状態を避ける
- **推奨間隔**: 
  - 小規模サイト：1リクエスト/10-15秒
  - 一般的なケース：1-2秒間隔
- **実装**: `sleep`関数を使用してリクエスト間に遅延を挿入
```perl
use Time::HiRes qw(sleep);
sleep(2); # 2秒待機
```
- robots.txtの`crawl-delay`ディレクティブに従う

#### User-Agentの設定
- **ベストプラクティス**: 明確で正直なUser-Agent文字列を設定
- 可能であれば連絡先メールアドレスを含める
- サイトオーナーが連絡を取れるようにし、信頼性を向上
```perl
$ua->transactor->name('MyBot/1.0 (contact@example.com)');
```

#### エラーハンドリング
- リクエストの成功/失敗を常にチェック
```perl
if ($res->is_error) { 
    warn $res->message;
}
```
- ネットワークエラーやタイムアウトに対する適切な処理
- リトライロジックの実装（特に一時的なエラーの場合）

#### 法的・倫理的な注意点
- **Terms of Service（利用規約）の確認**: 多くのサイトがスクレイピングを明示的に禁止
- **著作権と個人情報**:
  - 著作権で保護されたコンテンツのスクレイピングは要注意
  - 個人識別情報（PII）の収集には特別な配慮が必要
  - GDPR（EU）、CCPA（米国カリフォルニア州）などの規制に準拠
- **法的枠組み**:
  - 米国：Computer Fraud and Abuse Act (CFAA)に注意
  - EU：GDPR（個人データ保護）
- **APIの優先使用**: 公式APIがある場合は必ずそちらを使用
- **許可の取得**: 大規模なデータ収集の場合、サイトオーナーに事前連絡を検討

#### 参照元URL
- https://blog.froxy.com/en/ethical-web-scraping
- https://www.promptcloud.com/blog/robots-txt-scraping-compliance-guide/
- https://www.hystruct.com/articles/ethical-web-scraping
- https://www.roborabbit.com/blog/is-web-scraping-legal-5-best-practices-for-ethical-web-scraping-in-2024/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/web-crawling-system-esg-data/best-practices.html

---

### 3. 実践的なコード例に使えるサンプル

#### 簡単なHTMLページの取得例
```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
my $res = $ua->get('https://example.com/')->result;

if ($res->is_success) {
    say $res->body;
} else {
    die "Failed: " . $res->message;
}
```

#### CSSセレクタを使った要素の抽出
```perl
# タイトルの取得
my $title = $res->dom->at('title')->text;

# すべてのリンクを取得
$res->dom->find('a')->each(sub {
    my $link = shift;
    say $link->text, ' -> ', $link->attr('href');
});

# 特定のクラスを持つ要素
my @quotes = $res->dom->find('div.quote')->map(sub {
    my $text = $_->at('span.text')->text;
    my $author = $_->at('small.author')->text;
    return { text => $text, author => $author };
})->each;
```

#### 複数ページのクロール
```perl
my $url = 'https://example.com/page1';
while ($url) {
    my $res = $ua->get($url)->result;
    # データ抽出処理
    
    # 次のページリンクを取得
    my $next = $res->dom->at('li.next a');
    $url = $next ? $next->attr('href') : undef;
    
    sleep(2); # レート制限
}
```

#### JSON APIの利用例
```perl
# POST リクエストでJSONを送信
my $tx = $ua->post(
    'https://api.example.com/endpoint',
    json => { key1 => 'value1', key2 => 'value2' }
);

if (my $res = $tx->result && $tx->result->is_success) {
    my $data = $res->json; # JSONレスポンスをPerlデータ構造に変換
    use Data::Dumper;
    print Dumper($data);
}

# GETリクエストでJSON取得
my $value = $ua->get('https://api.example.com/data.json')->result->json;
```

#### 非同期・並列処理
```perl
# 非ブロッキングリクエスト
$ua->get('https://example.com' => sub {
    my ($ua, $tx) = @_;
    say $tx->result->dom->at('title')->text;
});
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Promise による並列処理
use Mojo::Promise;

my $promise1 = $ua->get_p('https://site1.com');
my $promise2 = $ua->get_p('https://site2.com');

Mojo::Promise->all($promise1, $promise2)->then(sub {
    my ($res1, $res2) = @_;
    say $res1->[0]->result->dom->at('title')->text;
    say $res2->[0]->result->dom->at('title')->text;
})->wait;
```

#### Mojo::DOMの詳細な使用例
```perl
use Mojo::DOM;

my $dom = Mojo::DOM->new('<div><p id="a">Test</p><p id="b">123</p></div>');

# IDで検索
say $dom->at('#b')->text; # 123

# すべての<p>要素
say $dom->find('p')->map('text')->join("\n");

# 属性による検索
say $dom->find('[id]')->map(attr => 'id')->join("\n");

# 要素の追加・削除
$dom->find('div p')->last->append('<p id="c">456</p>');
$dom->at('#c')->prepend($dom->new_tag('p', id => 'd', '789'));
$dom->find(':not(p)')->map('strip');
```

#### 参照元URL
- https://mojolicious.org/perldoc/Mojo/UserAgent
- https://mojolicious.org/perldoc/Mojo/DOM
- https://metacpan.org/pod/Mojo::DOM
- https://blogs.perl.org/users/tempire/2011/02/easy-dom-parsing-with-mojodom.html
- https://brightdata.com/blog/web-data/web-scraping-with-perl

---

### 4. 競合記事の分析

#### 日本語の主要記事

1. **Qiita: Mojo::UserAgentがスクレイピングツールとして便利**
   - URL: https://qiita.com/uchiko/items/2d925c23fa04b696fc7a
   - 特徴: 基本的な使い方を網羅、初心者向け
   - 構成: インストール → GET/POST → DOM解析 → 実践例
   - コード例が豊富で実践的

2. **PerlでのWebスクレイピング - Web::Scraper と Mojo::UserAgent**
   - URL: https://www.nqou.net/2025/12/22/000000/
   - 特徴: Web::Scraperとの比較を含む
   - 実践的なコード例と解説

3. **Perlプログラミング入門（Qiita）**
   - URL: https://qiita.com/automation2025/items/4ed0b725033bdc8bbb84
   - 特徴: Perl基礎からLWPによるスクレイピングまで段階的解説
   - 初心者が躓きやすいポイントを丁寧にフォロー

#### 英語の主要記事

1. **BrightData: Web Scraping with Perl Guide**
   - URL: https://brightdata.com/blog/web-data/web-scraping-with-perl
   - 特徴: Perlスクレイピング全般の包括的ガイド
   - モジュール比較、実践例、課題と解決策

2. **ETOOBUSY: Mojo::UserAgent introductory notes**
   - URL: https://etoobusy.polettix.it/2021/02/22/mojo-useragent-intro-notes/
   - 特徴: `result` vs `res` の違いなど、微妙な点を丁寧に解説
   - 初心者が理解しづらい部分に焦点

3. **YouTube: Perl Basics #23: Requests with Mojo::UserAgent**
   - URL: https://www.youtube.com/watch?v=z2_z7XHhgaM
   - 特徴: 動画で視覚的に学べる
   - 実際のコーディングの流れを確認可能

#### 読者に好まれる構成の傾向

1. **段階的な学習アプローチ**:
   - インストール → 基本的なGET → DOM解析 → 実践的な例
   - 各ステップでコード例を提示

2. **実行可能なコード例**:
   - コピー＆ペーストで動くサンプルコード
   - 具体的なユースケース（ニュースサイト、APIなど）

3. **トラブルシューティング**:
   - よくあるエラーとその解決方法
   - `result` vs `res` などの微妙な違いの説明

4. **倫理的・法的注意点**:
   - robots.txt、利用規約への配慮
   - スクレイピングのマナー

5. **視覚的要素**:
   - 図解やフローチャート
   - コードのシンタックスハイライト

---

### 5. 内部関連記事の調査

リポジトリ内で `perl`、`mojolicious`、`web-scraping` などのキーワードで検索した結果、以下のような記事が見つかりました：

#### Mojolicious関連
- **なにわPerlに行ってきた #naniwaperl** (2014/12/14)
  - tags: mojolicious, perl
  - Mojoliciousの仕組みについての議論

- **JSON::RPC::Spec v1.0.5 をリリースしました** (2015/11/16)
  - tags: mojolicious, perl
  - Mojoliciousと組み合わせたJSON-RPC実装

#### Perl関連記事
- **YAPC::Kyoto 2023に行けなかった私がボランティアスタッフになってみた** (2023/03/21)
  - tags: yapc
  - Perlコミュニティイベントの参加レポート

#### タグベースの関連性
- `perl` タグを持つ記事が多数存在（100件以上）
- `mojolicious` タグの記事は少数だが存在
- `web-scraping` タグの記事は確認されず（新規トピック）

#### 内部リンク候補
- Perlの基礎やCPANモジュールに関する既存記事
- Mojoliciousを使った他のアプリケーション開発記事
- Perlコミュニティイベントの参加報告

---

### 6. 参考リソース

#### 公式ドキュメント

1. **Mojolicious公式サイト**
   - URL: https://mojolicious.org/
   - 内容: フレームワーク全体の概要、Getting Started

2. **Mojolicious::Guides**
   - URL: https://docs.mojolicious.org/
   - URL: https://metacpan.org/dist/Mojolicious/view/lib/Mojolicious/Guides.pod
   - 内容: チュートリアル、ガイド、API リファレンス

3. **Mojo::UserAgent ドキュメント**
   - URL: https://mojolicious.org/perldoc/Mojo/UserAgent
   - URL: https://metacpan.org/pod/Mojo::UserAgent
   - 内容: メソッド詳細、使用例

4. **Mojo::DOM ドキュメント**
   - URL: https://mojolicious.org/perldoc/Mojo/DOM
   - URL: https://metacpan.org/pod/Mojo::DOM
   - 内容: CSSセレクタ、DOM操作メソッド

#### CPANモジュールページ

1. **Mojolicious on MetaCPAN**
   - URL: https://metacpan.org/dist/Mojolicious
   - URL: https://metacpan.org/pod/Mojolicious
   - 最新バージョン、変更履歴、依存関係

2. **GitHub Repository**
   - URL: https://github.com/mojolicious/mojo
   - ソースコード、Issue、コントリビューションガイド

#### 有用なチュートリアルやブログ記事

1. **blogs.perl.org - Easy DOM parsing with Mojo::DOM**
   - URL: https://blogs.perl.org/users/tempire/2011/02/easy-dom-parsing-with-mojodom.html
   - Mojo::DOMの基本的な使い方

2. **blogs.perl.org - CSS selector goodness in Mojo::DOM**
   - URL: https://blogs.perl.org/users/tempire/2011/02/css-selector-goodness-in-mojodom.html
   - CSSセレクタの詳細

3. **BrightData - Web Scraping with Perl Guide**
   - URL: https://brightdata.com/blog/web-data/web-scraping-with-perl
   - Perlスクレイピング全般の包括的ガイド

4. **Data Journal - Web Scraping in Perl: Step-by-Step Guide**
   - URL: https://www.data-journal.org/data-scraping/web-scraping-in-perl/
   - ステップバイステップの実践ガイド

5. **Scrape.do - Web Scraping in Perl**
   - URL: https://scrape.do/blog/web-scraping-in-perl/
   - 実践的なテクニックと高度な手法

6. **Perlゼミ**
   - URL: https://perlzemi.com/
   - 日本語でのPerl基礎学習サイト

#### 関連する書籍のASIN/ISBN

1. **Programming Perl (Camel Book)**
   - 著者: Larry Wall, Tom Christiansen, Jon Orwant
   - 特徴: Perlのバイブル、テキスト処理と自動化の基礎
   - 対象: 中級〜上級者
   - ISBN: 978-0596004927 (第4版)
   - ASIN: 0596004923

2. **Learning Perl**
   - 著者: Randal L. Schwartz, brian d foy, Tom Phoenix
   - 特徴: 初心者向けの定番入門書
   - 対象: 初心者
   - ISBN: 978-1491954324 (第7版)
   - ASIN: 1491954329

3. **Perl Cookbook**
   - 著者: Tom Christiansen, Nathan Torkington
   - 特徴: 問題解決型のレシピ集、スクレイピングにも応用可能
   - 対象: 中級者
   - ISBN: 978-0596003135 (第2版)
   - ASIN: 0596003137

4. **Mastering Perl**
   - 著者: brian d foy
   - 特徴: 上級者向け、プロフェッショナルな技術
   - 対象: 上級者
   - ISBN: 978-1449393090 (第2版)
   - ASIN: 144939309X

注: Perlスクレイピング専門の書籍は少ないため、上記は一般的なPerl書籍を推奨。スクレイピング技術は主にオンラインリソースやブログで学習するのが現代的。

---

## 発見・結論

### 主な発見

1. **Mojo::UserAgentの優位性**
   - 非ブロッキングI/O、統合されたDOM解析、Modern Perl対応
   - LWP::UserAgentより現代的で高機能
   - 初心者でも扱いやすいAPI設計

2. **ドキュメントの充実度**
   - 公式ドキュメントが非常に充実
   - 日本語記事も一定数存在するが、英語リソースが豊富
   - コミュニティも活発（GitHub、blogs.perl.org）

3. **倫理的配慮の重要性**
   - robots.txt、利用規約の遵守は必須
   - 法的リスク（CFAA、GDPR）への理解が重要
   - API優先の原則が広く推奨されている

4. **実践的な学習アプローチ**
   - 段階的な学習（基礎→応用）が効果的
   - 実行可能なコード例が学習効果を高める
   - トラブルシューティング情報が重要

5. **内部記事との連携**
   - Perl、Mojolicious関連の既存記事が多数存在
   - スクレイピング特化の記事は少なく、新規性がある
   - 内部リンクによるシリーズ化が可能

### 技術的結論

- **初心者向け推奨事項**:
  - まずMojoliciousのインストールから開始
  - 簡単なGETリクエストで基礎を理解
  - CSSセレクタの基本を習得
  - 段階的に非同期処理やエラーハンドリングへ進む

- **記事構成の推奨**:
  1. Mojo::UserAgentの概要と利点
  2. インストールと環境設定
  3. 基本的なGETリクエスト
  4. Mojo::DOMでのデータ抽出
  5. 実践例（ニュースサイトなど）
  6. 倫理的・法的配慮
  7. よくあるトラブルシューティング
  8. 次のステップ（非同期処理、API連携）

---

## 次のステップ（アウトライン作成への推奨事項）

### 記事のターゲット読者
- Perlの基礎知識はあるが、スクレイピングは初めての開発者
- LWP::UserAgentからの移行を検討している開発者
- Modern Perlの実践例を探している学習者

### 推奨する記事の構成

1. **導入部**
   - Webスクレイピングとは何か
   - なぜMojo::UserAgentを選ぶのか
   - 本記事で学べること

2. **準備編**
   - Mojoliciousのインストール
   - 動作環境の確認（Perlバージョン）
   - 最初のスクリプト実行

3. **基礎編**
   - GETリクエストの基本
   - レスポンスの確認とエラーハンドリング
   - HTMLの取得と表示

4. **データ抽出編**
   - Mojo::DOMの紹介
   - CSSセレクタの基本
   - 実践的な抽出例（タイトル、リンク、テキスト）

5. **実践編**
   - 実際のWebサイトからのデータ取得例
   - 複数ページのクロール
   - データの保存（CSV、JSONなど）

6. **応用編**
   - POSTリクエストとフォーム送信
   - JSON APIとの連携
   - 非同期処理の基礎

7. **重要な注意点**
   - robots.txtの確認方法
   - レート制限の実装
   - 倫理的・法的配慮

8. **トラブルシューティング**
   - よくあるエラーと解決方法
   - デバッグのコツ

9. **まとめ**
   - 学んだことの復習
   - さらなる学習リソース
   - コミュニティへの参加

### コンテンツ作成時の注意点

1. **コード例の質**
   - すべてのコード例は実行可能であること
   - 適切なコメントを含める
   - エラーハンドリングを忘れずに

2. **段階的な難易度設定**
   - 基礎から応用へ自然に進む
   - 各セクションで1つの概念に集中

3. **視覚的要素**
   - コードのシンタックスハイライト
   - 可能であれば図解やフローチャート
   - 実行結果のスクリーンショット

4. **実践性の重視**
   - 実際のユースケースを想定
   - 読者がすぐに試せる例を提供

5. **倫理的側面の強調**
   - スクレイピングのマナーを明確に
   - 法的リスクについて警告
   - 責任あるデータ収集の重要性

### SEO対策キーワード

- プライマリ: "Mojo::UserAgent", "Perl スクレイピング", "Mojolicious 入門"
- セカンダリ: "Mojo::DOM", "Perl Web scraping", "Mojolicious tutorial"
- ロングテール: "Mojo::UserAgent 使い方", "Perl 初心者 スクレイピング", "Mojolicious スクレイピング 例"

### 推奨タグ
- perl
- mojolicious
- web-scraping
- tutorial
- mojo-useragent
- beginners

### 想定される読者の質問と回答準備

1. **Q: LWP::UserAgentとの違いは？**
   - A: Modern Perl対応、統合DOM解析、非同期処理のサポート

2. **Q: JavaScriptが必要なサイトはスクレイピングできる？**
   - A: Mojo::UserAgent単体では困難。Seleniumなどの併用を検討

3. **Q: スクレイピングは合法？**
   - A: ケースバイケース。robots.txt、利用規約、法的規制を確認

4. **Q: どのくらいの頻度でリクエストして良い？**
   - A: 一般的に1-2秒間隔。robots.txtのcrawl-delayに従う

### 内部リンク候補
- Perlの基礎に関する既存記事
- Mojoliciousを使った他のプロジェクト記事
- JSON-RPCなど関連技術の記事

### 外部リンク候補（ショートコード使用）
- Mojolicious公式サイト
- MetaCPAN Mojo::UserAgentページ
- Perlゼミ
- 倫理的スクレイピングのガイドライン

---

## 調査実施コマンド・方法

1. **リポジトリ内検索**
   - `grep`コマンドで `perl|mojolicious|web-scraping|scraping|mojo` をキーワードに検索
   - 既存記事のフロントマター（特にタグ）を確認

2. **Web検索**
   - "Mojo::UserAgent Perl web scraping tutorial 2024 2025"
   - "Mojolicious 最新バージョン 動作要件 Perl version"
   - "Perl web scraping best practices robots.txt ethical legal"
   - "Mojo::DOM CSS selector tutorial examples Perl"
   - "Mojolicious CPAN metacpan documentation official"
   - "Perl スクレイピング 入門 初心者 日本語 チュートリアル"
   - "Mojo::UserAgent POST request JSON API example Perl"
   - "Perl scraping book ISBN ASIN recommendation 2024"
   - "Mojo::UserAgent スクレイピング 入門 記事 日本語"
   - "Mojo::UserAgent tutorial beginner guide popular blog"

3. **情報源の評価**
   - 公式ドキュメントを優先
   - コミュニティで信頼されているブログ（blogs.perl.org）
   - 技術的権威性のあるサイト（MetaCPAN、GitHub）
   - 日本語・英語両方のリソースを確認

---

## 更新履歴

- 2024年12月29日: 初版作成
