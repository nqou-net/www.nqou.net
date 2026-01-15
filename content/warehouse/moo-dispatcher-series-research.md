---
date: 2025-12-30T19:40:48+09:00
description: シリーズ記事「Mooを使ってディスパッチャーを作ってみよう」（全12回）作成のための調査・情報収集結果
draft: false
epoch: 1767091248
image: /favicon.png
iso8601: 2025-12-30T19:40:48+09:00
title: '調査ドキュメント - Mooを使ってディスパッチャーを作ってみよう（シリーズ記事）'
---

# 調査ドキュメント：Mooを使ってディスパッチャーを作ってみよう

## 調査目的

シリーズ記事「Mooを使ってディスパッチャーを作ってみよう」（全12回）を作成するための情報収集と調査。

- **技術スタック**: Perl / Moo
- **想定読者**: Mooの基本的な使い方はわかっているPerl初心者
- **想定ペルソナ**: ルーターやディスパッチの仕組みに興味がある
- **目標**: PerlでStrategy パターンの書き方が身につく
- **背景**: 「Mooで覚えるオブジェクト指向プログラミング」シリーズ（全12回）の続編として位置づけ
- **ストーリー**: BBSに機能を追加していく過程で、if/elseだけでは解決が難しい状況になり、ルーターやディスパッチの必要性に気づき、デザインパターンを学ぶ

**調査実施日**: 2025年12月30日

---

## 1. キーワード調査

### 1.1 Strategy パターン（デザインパターン）

**要点**:

- Strategy パターンは「振る舞いのデザインパターン」の一つ
- アルゴリズム（処理ロジック）を独立したクラスとしてカプセル化し、実行時に切り替え可能にする
- 「Context（文脈）」「Strategy Interface（戦略インターフェース）」「Concrete Strategy（具体的な戦略）」の3つの要素で構成
- if/elseやswitch文の肥大化を防ぎ、Open/Closed原則（拡張に開き、修正に閉じる）に従う

**根拠**:

- GoF（Gang of Four）のデザインパターンブックで定義された23パターンの一つ
- 実行時にアルゴリズムを切り替える必要がある場面で広く使用される

**仮定**:

- 読者はデザインパターンという言葉自体に馴染みがない可能性が高い
- 「パターン」という言葉から「定石」「お約束」の意味を伝えると理解しやすい

**出典**:

- https://en.wikipedia.org/wiki/Strategy_pattern （Wikipedia）
- https://refactoring.guru/design-patterns/strategy （Refactoring Guru）
- https://www.geeksforgeeks.org/system-design/strategy-pattern-set-1/ （GeeksforGeeks）
- https://www.freecodecamp.org/news/a-beginners-guide-to-the-strategy-design-pattern/ （FreeCodeCamp）

**信頼度**: 高（複数の著名な技術解説サイトで一致した説明）

---

### 1.2 ルーター/ディスパッチャーの概念

**要点**:

- ルーター（Router）は、リクエストされたURLやパスに基づいて、適切な処理（ハンドラー）に振り分ける機構
- ディスパッチャー（Dispatcher）は、ルーターが決定した振り分け先に実際に処理を委譲する機構
- WebフレームワークではこれらがURLとコントローラーアクションを紐付ける中核機能
- 「どこに処理を振り分けるか決める」→ルーター、「決まった先に処理を渡す」→ディスパッチャー

**根拠**:

- MojoliciousやCatalystなど、Perlの主要なWebフレームワークはすべてルーティング機構を持つ
- JSON-RPC::Specでもディスパッチャー機能を実装している（内部リンク記事より）

**仮定**:

- 読者は「ルーター」という言葉はネットワーク機器と混同する可能性がある
- 「振り分け」「マッチング」という日本語で説明すると分かりやすい

**出典**:

- https://mojolicious.org/perldoc/Mojolicious/Guides/Routing （Mojolicious公式）
- https://metacpan.org/pod/Router::Simple （Router::Simple）
- 内部記事: `/2015/11/16/083646/`（JSON::RPC::Specでのディスパッチャー）

**信頼度**: 高

---

### 1.3 PerlでのStrategy パターン実装

**要点**:

- PerlではMoo::Roleを「Strategy Interface」として使用できる
- `requires`で必須メソッドを定義し、各Concrete StrategyクラスがRoleを消費（with）
- Contextクラスは属性としてStrategyオブジェクトを保持し、委譲（handles）またはメソッド呼び出し

**根拠**:

- 「Design Patterns in Modern Perl」（Mohammad Sajid Anwar著）で詳細に解説
- GitHub上にMoose/Moo向けのデザインパターン実装例が複数存在

**コード例（Moo）**:

```perl
# Strategy Role
package PaymentStrategy;
use Moo::Role;
requires 'pay';
1;

# Concrete Strategy
package PaypalStrategy;
use Moo;
with 'PaymentStrategy';

sub pay {
    my ($self, $amount) = @_;
    print "Paying $amount via PayPal\n";
}
1;

# Context
package PaymentContext;
use Moo;

has strategy => (is => 'rw', required => 1);

sub pay {
    my ($self, $amount) = @_;
    $self->strategy->pay($amount);
}
1;
```

**出典**:

- https://leanpub.com/design-patterns-in-modern-perl （書籍）
- https://perlschool.com/books/design-patterns/ （Perl School）
- https://github.com/jmcveigh/p5-moose-design-patterns （GitHub実装例）
- https://github.com/jeffa/DesignPatterns-Perl （GitHub実装例）

**信頼度**: 高

---

### 1.4 Mooを使ったディスパッチャー

**要点**:

- Mooの`has`と`sub`でディスパッチテーブル（ハッシュ）を構築可能
- Router::Simpleのようなモジュールと組み合わせてパターンマッチングを実現
- ディスパッチ先はオブジェクトのメソッドまたはコードリファレンス

**根拠**:

- JSON::RPC::SpecはRouter::Simpleを使ってディスパッチを実装
- Mojoliciousのルーティングは内部的にディスパッチテーブルを構築

**仮定**:

- 読者は前シリーズで`has`、`sub`、`handles`を学んでいる前提
- ハッシュとコードリファレンスについては基本的な理解がある

**出典**:

- https://metacpan.org/pod/Router::Simple （Router::Simple）
- https://metacpan.org/pod/JSON::RPC::Spec （JSON::RPC::Spec）
- 内部記事: `/2014/08/14/221829/`（JSON::RPC::Specでのルーティング）

**信頼度**: 高

---

### 1.5 if/elseの問題点とリファクタリング

**要点**:

- 条件分岐（if/else、switch）の増加は以下の問題を引き起こす:
  1. コードの可読性低下（数百行のif/elseチェーン）
  2. 修正時の影響範囲が広い（1箇所変更で全体に影響）
  3. テストの困難さ（全分岐を網羅する必要）
  4. Open/Closed原則違反（新しい条件追加のたびに既存コード修正）
- Strategy/Command/Factoryパターンへのリファクタリングで解決

**根拠**:

- リファクタリング関連の技術記事で繰り返し取り上げられるトピック
- 実際のプロダクションコードで頻繁に発生する問題

**仮定**:

- 読者は掲示板を拡張する過程でif/elseが増えて困った経験をシミュレーションできる
- 「あるある」と共感できる具体例を提示することで動機付けになる

**出典**:

- https://dev.to/tamerardal/dont-use-if-else-blocks-anymore-use-strategy-and-factory-pattern-together-4i77 （Dev.to）
- https://codingtechroom.com/question/-refactor-if-else-to-strategy-pattern （CodingTechRoom）
- https://stackoverflow.com/questions/28049094/replacing-if-else-statement-with-pattern （StackOverflow）

**信頼度**: 高

---

### 1.6 Command パターン（関連）

**要点**:

- リクエストをオブジェクトとしてカプセル化するパターン
- 実行、取り消し、キューイング、ログなどの操作が可能
- Strategyパターンが「どう処理するか」の切り替えなら、Commandパターンは「何を処理するか」のカプセル化
- ディスパッチャーと組み合わせて、コマンドオブジェクトを振り分ける設計が可能

**根拠**:

- GoFデザインパターンの一つ
- Undo/Redo機能やジョブキューの実装で広く使用

**仮定**:

- 本シリーズではCommandパターン自体の深い解説は範囲外
- Strategyとの違いを軽く触れる程度で十分

**出典**:

- https://refactoring.guru/design-patterns/command （Refactoring Guru）
- https://www.in-com.com/blog/refactoring-repetitive-logic-let-the-command-pattern-take-over/ （In-Com）

**信頼度**: 高

---

### 1.7 Factory パターン（関連）

**要点**:

- オブジェクトの生成ロジックをカプセル化するパターン
- クライアントコードから具体的なクラス名を隠蔽
- Strategyパターンと組み合わせて、「どのStrategyを使うか」の決定をFactoryに委ねる設計が一般的
- 「Strategy + Factory」の組み合わせはif/else削減の定番手法

**根拠**:

- GoFデザインパターンの一つ（Factory Method, Abstract Factory）
- 実務でStrategyと組み合わせて使用されることが多い

**仮定**:

- 本シリーズでは簡易的なFactory（ディスパッチテーブル）を扱う
- 本格的なFactory Methodパターンは応用として触れる程度

**出典**:

- https://refactoring.guru/design-patterns/factory-method （Refactoring Guru）
- https://adityam31.github.io/posts/designpatterns-strategy-factory-pattern/ （Aditya M Blog）

**信頼度**: 高

---

### 1.8 Perl/MooのWebフレームワークでのルーティング実装

**要点**:

- **Mojolicious**: 強力なルーティングシステム、プレースホルダー、正規表現マッチング
- **Router::Simple**: 軽量なルーティングライブラリ、ハッシュベースのディスパッチ
- **Router::Boom**: 高速なルーティングライブラリ
- **Path::Router**: パスベースのルーティング

**根拠**:

- 内部記事でRouter::SimpleとJSON::RPC::Specの使用例が存在
- Mojoliciousはルーティングガイドを公式ドキュメントで詳細に解説

**出典**:

- https://mojolicious.org/perldoc/Mojolicious/Guides/Routing （Mojolicious Routing）
- https://metacpan.org/pod/Router::Simple （Router::Simple）
- https://metacpan.org/pod/Router::Boom （Router::Boom）

**信頼度**: 高

---

## 2. 競合記事の分析

### 2.1 主要な競合・参考記事

| サイト名 | 特徴 | URL |
|---------|------|-----|
| **Refactoring Guru - Strategy** | 図解が豊富、多言語対応、初心者向け | https://refactoring.guru/design-patterns/strategy |
| **GeeksforGeeks - Strategy** | コード例が充実、Java中心だがわかりやすい | https://www.geeksforgeeks.org/system-design/strategy-pattern-set-1/ |
| **FreeCodeCamp - Strategy** | 入門者向け、実践的なユースケース | https://www.freecodecamp.org/news/a-beginners-guide-to-the-strategy-design-pattern/ |
| **Design Patterns in Modern Perl** | Perl特化、Moo/Moose対応、書籍 | https://leanpub.com/design-patterns-in-modern-perl |
| **Mojolicious Routing Guide** | Perl公式、実践的なルーティング | https://mojolicious.org/perldoc/Mojolicious/Guides/Routing |

### 2.2 競合記事との差別化ポイント

**既存記事の問題点**:

1. 抽象的な例（支払い方法、交通手段など）が多く、継続性がない
2. 「なぜデザインパターンが必要か」の動機付けが弱い
3. Perl/Mooに特化した日本語の良質なチュートリアルが少ない
4. ルーター/ディスパッチャーとデザインパターンを結びつけた解説がない

**本シリーズの強み**:

1. **ストーリー駆動**: 掲示板BBSの拡張という具体的な物語
2. **前シリーズからの継続性**: 「Mooで覚えるオブジェクト指向プログラミング」で作ったBBSを題材に発展
3. **問題発見→解決の流れ**: if/elseの問題を体験してからパターンを学ぶ
4. **段階的な難易度**: 1記事1概念、コード例2つまでの制約
5. **「気づき」の演出**: パターンを学んだ後に「これがStrategy パターンだったのか！」と気づく構成

---

## 3. 内部リンク調査

### 3.1 直接関連する記事（前シリーズ「Mooで覚えるオブジェクト指向プログラミング」）

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2021/10/31/191008.md` | 第1回-Mooで覚えるオブジェクト指向プログラミング | `/2021/10/31/191008/` | **最高** |
| `/content/post/2025/12/30/163810.md` | 第2回-データとロジックをまとめよう | `/2025/12/30/163810/` | **最高** |
| `/content/post/2025/12/30/163811.md` | 第3回-オブジェクトを複数作る | `/2025/12/30/163811/` | **最高** |
| `/content/post/2025/12/30/163812.md` | 第4回-読み書きを制限する | `/2025/12/30/163812/` | **最高** |
| `/content/post/2025/12/30/163813.md` | 第5回-必須と初期値を設定する | `/2025/12/30/163813/` | **最高** |
| `/content/post/2025/12/30/163814.md` | 第6回-カプセル化 | `/2025/12/30/163814/` | **最高** |
| `/content/post/2025/12/30/163815.md` | 第7回-複数クラスの連携 | `/2025/12/30/163815/` | **最高** |
| `/content/post/2025/12/30/163816.md` | 第8回-継承 | `/2025/12/30/163816/` | **最高** |
| `/content/post/2025/12/30/163817.md` | 第9回-オーバーライド | `/2025/12/30/163817/` | **最高** |
| `/content/post/2025/12/30/163818.md` | 第10回-ロール | `/2025/12/30/163818/` | **最高** |
| `/content/post/2025/12/30/163819.md` | 第11回-委譲 | `/2025/12/30/163819/` | **最高** |
| `/content/post/2025/12/30/163820.md` | 第12回-型チェック | `/2025/12/30/163820/` | **最高** |

### 3.2 ルーター/ディスパッチャー関連

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2015/11/16/083646.md` | JSON::RPC::Spec v1.0.5（ディスパッチャー機能） | `/2015/11/16/083646/` | **高** |
| `/content/post/2014/08/14/221829.md` | JSON::RPC::Specバージョンアップ（Router::Simple） | `/2014/08/14/221829/` | **高** |
| `/content/post/2025/12/04/000000.md` | Mojolicious入門（ルーティング解説含む） | `/2025/12/04/000000/` | **高** |

### 3.3 デザインパターン・オブジェクト指向関連

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2025/12/25/234500.md` | JSON-RPC Request/Response実装（Strategy的な構造） | `/2025/12/25/234500/` | 中 |
| `/content/post/2016/02/21/150920.md` | よなべPerlでMooについて | `/2016/02/21/150920/` | 中 |
| `/content/post/2015/09/17/072209.md` | よなべPerlで講師（Moo、オブジェクト指向） | `/2015/09/17/072209/` | 中 |

### 3.4 Perl基礎・その他

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/post/2025/12/01/235959.md` | Perl Advent Calendar 2025 | `/2025/12/01/235959/` | 低 |
| `/content/post/2000/10/07/133116.md` | フォームからの入力（古典的BBS） | `/2000/10/07/133116/` | 低 |

---

## 4. 情報源リスト（技術的正確性の担保）

### 4.1 公式ドキュメント

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **Moo公式ドキュメント** | https://metacpan.org/pod/Moo | 属性定義、Role、継承 |
| **Moo::Role** | https://metacpan.org/pod/Moo::Role | Strategy Interface実装 |
| **Types::Standard** | https://metacpan.org/pod/Types::Standard | 型制約 |
| **Router::Simple** | https://metacpan.org/pod/Router::Simple | ルーティング参考 |
| **Mojolicious Routing** | https://mojolicious.org/perldoc/Mojolicious/Guides/Routing | ルーティング概念 |

### 4.2 デザインパターン解説サイト

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **Refactoring Guru** | https://refactoring.guru/design-patterns | パターン全般の解説、図解 |
| **Wikipedia - Strategy** | https://en.wikipedia.org/wiki/Strategy_pattern | 正式な定義 |
| **GeeksforGeeks** | https://www.geeksforgeeks.org/system-design/strategy-pattern-set-1/ | コード例 |

### 4.3 書籍

| 書籍名 | ASIN/ISBN | 用途 |
|-------|-----------|------|
| **Design Patterns in Modern Perl** | Leanpub | PerlでのGoFパターン実装 |
| **オブジェクト指向における再利用のためのデザインパターン（GoF本）** | 4797311126 | デザインパターンの原典 |
| **初めてのPerl 第7版** | B01LYGT22U | Perl基礎 |
| **続・初めてのPerl 改訂第2版** | B00XWE9RBK | オブジェクト指向 |

### 4.4 GitHub実装例

| リソース名 | URL | 用途 |
|-----------|-----|------|
| **p5-moose-design-patterns** | https://github.com/jmcveigh/p5-moose-design-patterns | Mooseでのパターン実装 |
| **DesignPatterns-Perl** | https://github.com/jeffa/DesignPatterns-Perl | GoFパターン in Perl |
| **JSON-RPC-Spec** | https://github.com/nqounet/p5-json-rpc-spec | ディスパッチャー実装例 |

---

## 5. 付録：調査中に発見した有用な情報

### 5.1 Perl特有の実装ポイント

**コードリファレンス**:
- Perlではサブルーチンを変数に代入可能: `my $handler = sub { ... };`
- ディスパッチテーブルとして自然に使える: `$handlers{$action}->()`

**Moo::Roleでのrequires**:
- Strategyインターフェースとして機能
- 未実装の場合はコンパイル時エラー

**handlesとの組み合わせ**:
- Contextクラスからの委譲をhandlesで簡潔に記述可能

### 5.2 読者が陥りやすい落とし穴

1. **過剰なパターン適用**: シンプルなif/elseで十分な場面でパターンを使いすぎる
2. **クラス爆発**: 各条件に対して1クラス作ることへの抵抗感
3. **抽象化のタイミング**: いつリファクタリングすべきかの判断

---

**調査完了**: 2025年12月30日
