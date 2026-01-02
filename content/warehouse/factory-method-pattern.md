---
date: 2025-12-31T05:46:00+09:00
description: Factory Methodパターンの包括的調査：定義、構造、実装例(Perl含む)、メリット・デメリット、使用場面、競合記事分析
draft: false
epoch: 1767127560
image: /favicon.png
iso8601: 2025-12-31T05:46:00+09:00
tags:
  - design-patterns
  - factory-method
  - gof
  - creational-patterns
  - perl
title: Factory Method(ファクトリーメソッド)パターン調査ドキュメント
---

# Factory Method(ファクトリーメソッド)パターン調査ドキュメント

## 調査目的

Factory Method(ファクトリーメソッド)デザインパターンについて包括的な調査を行い、その定義、目的、構造、実装例(特にPerl)、利点・欠点、適用場面を明らかにする。技術記事執筆時の正確性担保のための情報源を整備する。

- **調査対象**: Factory Methodパターンの定義、構造、実装、利用場面
- **想定読者**: デザインパターンを学ぶソフトウェアエンジニア、Perl開発者
- **調査実施日**: 2025年12月31日

---

## 1. Factory Methodパターンの概要

### 1.1 定義

**要点**:

Factory Method(ファクトリーメソッド)パターンは、GoFの生成パターン(Creational Pattern)の一つです。**オブジェクト生成のインターフェースを定義し、実際にインスタンス化するクラスの決定をサブクラスに委譲する**パターンです。

具体的には:
- 親クラス(Creator)がオブジェクト生成用のメソッド(Factory Method)を定義
- サブクラス(ConcreteCreator)が実際の生成処理を実装
- クライアントコードは具体的なクラスを知らずにオブジェクトを利用できる

**根拠**:

GoF書籍において「Define an interface for creating an object, but let subclasses decide which class to instantiate(オブジェクト生成のためのインターフェースを定義するが、どのクラスをインスタンス化するかはサブクラスに決めさせる)」と定義されています。

この定義から、Factory Methodパターンの本質は「生成処理の委譲による柔軟性の向上」であることが分かります。

**仮定**:

- オブジェクト指向プログラミングの基本概念(クラス、継承、ポリモーフィズム)を理解している
- 「オープン・クローズドの原則(OCP)」—拡張に対して開いていて、変更に対して閉じている—を目指す設計を良しとする

**出典**:

- Wikipedia: Factory method pattern - https://en.wikipedia.org/wiki/Factory_method_pattern
- GeeksforGeeks: Factory method Design Pattern - https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/
- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method

**信頼度**: 高(GoF原典および著名な技術サイト)

---

### 1.2 目的

**要点**:

Factory Methodパターンの主な目的は以下の通りです:

1. **疎結合の実現**: クライアントコードと具体的な実装クラスとの依存関係を排除
2. **拡張性の向上**: 新しい製品タイプの追加が既存コードの変更なしで可能
3. **オープン・クローズドの原則(OCP)への適合**: 変更ではなく拡張で機能追加
4. **インスタンス生成ロジックのカプセル化**: 複雑な生成処理を一箇所に集約

**根拠**:

- オブジェクト生成を専用のメソッドに委譲することで、クライアントは「何を作るか(What)」だけを指定し、「どう作るか(How)」を知る必要がなくなる
- 新しい製品クラスを追加する際、ConcreteCreatorを追加するだけで対応でき、既存の親クラスやクライアントコードの変更が不要

**具体例**:

- **Webブラウザのプラグインシステム**: ブラウザ(Creator)は各種プラグイン(Product)の生成方法を知らず、プラグインローダー(ConcreteCreator)が具体的なプラグインをインスタンス化
- **ペイメントゲートウェイ**: 支払いシステムが実行時にStripe、PayPal、クレジットカードなどの決済プロセッサを選択

**出典**:

- DEV Community: Factory Design Pattern in Java - https://dev.to/zeeshanali0704/factory-design-pattern-in-java-a-complete-guide-dgj
- Software Patterns Lexicon: Factory Method Pattern - https://softwarepatternslexicon.com/mastering-design-patterns/creational-design-patterns/factory-method-pattern/

**信頼度**: 高

---

### 1.3 基本構造

**要点**:

Factory Methodパターンは以下の4つの要素で構成されます:

| 要素 | 役割 | 説明 |
|------|------|------|
| **Product** | 製品インターフェース | 生成されるオブジェクトの共通インターフェース(抽象クラスまたはロール) |
| **ConcreteProduct** | 具体的な製品 | Productインターフェースの具体実装 |
| **Creator** | 生成者(抽象) | Factory Methodを宣言し、デフォルト実装を提供する場合もある |
| **ConcreteCreator** | 具体的な生成者 | Factory Methodをオーバーライドし、ConcreteProductを返す |

**UML構造図(概念)**:

```text
<<interface>>
   Product
   +operation()
       ↑
       | implements
       |
+------+-------+
|              |
ConcreteProductA  ConcreteProductB

<<abstract>>
   Creator
   +factoryMethod(): Product
   +someOperation()
       ↑
       | extends
       |
+------+-------+
|              |
ConcreteCreatorA  ConcreteCreatorB
+factoryMethod()  +factoryMethod()
  returns ProductA  returns ProductB
```

**クラス間の関係**:

1. Creator(親クラス)は、factoryMethod()を宣言し、Productインターフェースを返す
2. ConcreteCreator(サブクラス)は、factoryMethod()をオーバーライドして具体的なConcreteProductインスタンスを返す
3. クライアントはCreatorのメソッドを呼び出し、Productインターフェースを通じてオブジェクトを操作

**根拠**:

この構造により、クライアントは具体的なConcreteProductのクラス名を知る必要がなく、Creatorのインターフェースを通じてオブジェクトを取得できます。これが疎結合を実現する仕組みです。

**出典**:

- GeeksforGeeks: Factory Method Design Pattern in Java - https://www.geeksforgeeks.org/java/factory-method-design-pattern-in-java/
- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method

**信頼度**: 高

---

## 2. Factory Methodパターンの用途

### 2.1 どのような場面で使うべきか

**要点**:

Factory Methodパターンは以下のような状況で特に有効です:

#### 場面1: クラスが生成すべきオブジェクトの型を事前に予測できない場合

- **状況**: システムが扱うオブジェクトの種類が実行時に決まる、または頻繁に変更される
- **例**: ドキュメントエディタで、ファイル拡張子に応じて異なるドキュメントクラス(PDF、Word、Excelなど)を生成

#### 場面2: オブジェクト生成ロジックが複雑または変化しやすい場合

- **状況**: インスタンス生成に複雑な条件分岐や設定が必要で、その処理を一箇所に集約したい
- **例**: データベース接続の生成(開発環境・本番環境で異なる設定を適用)

#### 場面3: 拡張性を重視する場合(新しい型を追加する可能性が高い)

- **状況**: 将来的に新しい製品タイプが追加される可能性が高く、既存コードの変更を最小限に抑えたい
- **例**: ゲーム開発でのエンティティ生成(敵キャラ、アイテム、NPCなど)

#### 場面4: フレームワークやライブラリの設計

- **状況**: ライブラリ利用者が独自の実装を差し込めるようにしたい
- **例**: ロギングフレームワークで、ユーザーが独自のLogger実装を提供できる仕組み

**反例(使うべきでない場合)**:

- 生成するオブジェクトの種類が1つまたは固定で、変更の予定がない場合
- シンプルな`new`による生成で十分な小規模プロジェクト
- 過度な抽象化がコードの可読性を損なう場合

**根拠**:

Factory Methodパターンはクラス数の増加というコストを伴うため、拡張性や保守性のメリットがコストを上回る場合にのみ適用すべきです。

**出典**:

- JavaTechOnline: Factory Method Design Pattern in Java - https://javatechonline.com/factory-method-design-pattern-in-java-analogy/
- Naukri Code 360: Factory Design Pattern in Java with Examples - https://www.naukri.com/code360/library/factory-design-pattern
- Qiita: 【デザインパターン】ファクトリーメソッドパターン解説 - https://qiita.com/nozomi2025/items/4a68d12a1fc539b1a582

**信頼度**: 高

---

### 2.2 実践的なユースケース

**要点**:

Factory Methodパターンの実践的な適用例:

| 領域 | ユースケース | 具体例 |
|------|-------------|--------|
| **フロントエンド** | UIコンポーネント生成 | ボタン、モーダル、フォームをテーマに応じて生成 |
| **バックエンド** | データアクセス層 | MySQL、PostgreSQL、MongoDBなどのDAOを動的に選択 |
| **組み込み** | センサードライバ | 温度センサー、湿度センサーなどのドライバを統一インターフェースで管理 |
| **クラウド** | ストレージプロバイダ | AWS S3、Azure Blob、GCS を抽象化して切り替え可能に |
| **ゲーム開発** | エンティティ生成 | 敵キャラクター、アイテム、NPCの種類を動的に生成 |
| **通知システム** | 通知チャネル | Email、SMS、Pushなどの通知手段を実行時に選択 |

**具体例1: ドキュメント生成システム**

```text
Creator: DocumentFactory
ConcreteCreator: PDFFactory, WordFactory, ExcelFactory
Product: Document (interface)
ConcreteProduct: PDFDocument, WordDocument, ExcelDocument
```

クライアントは「PDFを生成したい」と指定するだけで、PDFFactoryが適切なPDFDocumentインスタンスを返す。

**具体例2: 通知システム**

```text
Creator: NotificationSender
ConcreteCreator: EmailSender, SMSSender, PushNotificationSender
Product: Notification (interface)
ConcreteProduct: EmailNotification, SMSNotification, PushNotification
```

**出典**:

- GeeksforGeeks: Factory method Design Pattern - https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/
- prgrmmng.com: Factory Method Pattern in Java – With Real-World Examples - https://prgrmmng.com/factory-method-pattern-java

**信頼度**: 高

---

## 3. 具体的なサンプルコード

### 3.1 Perlでの実装例(Mooを使用)

**要点**:

MooはPerlのモダンなオブジェクト指向システムで、ロール(Role)を使った柔軟な設計が可能です。Factory Methodパターンの実装に最適です。

#### ステップ1: Productロールの定義

```perl
package Shape;
use Moo::Role;

# 全ての具体的な形状クラスはdraw()メソッドを実装する必要がある
requires 'draw';

1;
```

**解説**: `requires 'draw'`により、このロールを使用するクラスは必ず`draw`メソッドを実装しなければなりません。これがProductインターフェースに相当します。

---

#### ステップ2: ConcreteProduct(具体的な製品)の実装

```perl
package Circle;
use Moo;
with 'Shape';  # Shapeロールを適用

sub draw {
    my $self = shift;
    print "Drawing Circle\n";
}

1;
```

```perl
package Square;
use Moo;
with 'Shape';

sub draw {
    my $self = shift;
    print "Drawing Square\n";
}

1;
```

```perl
package Rectangle;
use Moo;
with 'Shape';

sub draw {
    my $self = shift;
    print "Drawing Rectangle\n";
}

1;
```

---

#### ステップ3: ShapeFactory(Factory Method)の実装

```perl
package ShapeFactory;
use strict;
use warnings;

# Factory Method - 形状タイプに応じたオブジェクトを生成
sub create {
    my ($class, $type) = @_;
    
    # ディスパッチテーブル(型名→生成サブルーチンのマッピング)
    my %creators = (
        circle    => sub { Circle->new },
        square    => sub { Square->new },
        rectangle => sub { Rectangle->new },
    );
    
    # 未知の型の場合はエラー
    die "Unknown shape type: $type\n" unless exists $creators{$type};
    
    # 対応する生成サブルーチンを呼び出してインスタンスを返す
    return $creators{$type}->();
}

1;
```

**解説**: 
- `%creators`はディスパッチテーブルで、型名とオブジェクト生成ロジックをマッピング
- 新しい形状を追加する際は、`%creators`に新しいエントリを追加するだけ
- クライアントは具体的なクラス名(Circle、Squareなど)を知る必要がない

---

#### ステップ4: クライアントコードでの使用

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use ShapeFactory;

# 円を生成して描画
my $shape1 = ShapeFactory->create('circle');
$shape1->draw();  # 出力: Drawing Circle

# 四角形を生成して描画
my $shape2 = ShapeFactory->create('square');
$shape2->draw();  # 出力: Drawing Square

# 長方形を生成して描画
my $shape3 = ShapeFactory->create('rectangle');
$shape3->draw();  # 出力: Drawing Rectangle

# 未知の型を指定した場合
eval {
    my $shape4 = ShapeFactory->create('triangle');
};
if ($@) {
    print "Error: $@";  # 出力: Error: Unknown shape type: triangle
}
```

**利点の実証**:
1. **疎結合**: クライアントはCircle、Squareなどの具体クラスを直接知らない
2. **拡張性**: 新しい形状(例: Triangle)を追加する際、ShapeFactoryの`%creators`に追加するだけ
3. **保守性**: 生成ロジックが一箇所(ShapeFactory)に集約されている

---

### 3.2 より高度な実装例: Perl 5.38+ のclassを使用

**要点**:

Perl 5.38以降では実験的に`class`構文が導入されました。これを使ったよりモダンな実装例です。

```perl
use v5.38;
use experimental 'class';

# Product (基底クラス)
class Shape {
    method draw { die "draw() must be implemented by subclass\n" }
}

# ConcreteProduct: Circle
class Circle :isa(Shape) {
    method draw { say "Drawing Circle"; }
}

# ConcreteProduct: Square
class Square :isa(Shape) {
    method draw { say "Drawing Square"; }
}

# Factory Method
sub shape_factory {
    my $type = shift;
    
    return Circle->new if $type eq 'circle';
    return Square->new if $type eq 'square';
    
    die "Unknown type: $type\n";
}

# クライアントコード
my $s1 = shape_factory('circle');
$s1->draw();  # 出力: Drawing Circle

my $s2 = shape_factory('square');
$s2->draw();  # 出力: Drawing Square
```

**根拠**:

Perl 5.38の`class`構文は、より直感的でモダンなオブジェクト指向スタイルを提供します。ただし、まだ実験的機能であり、本番環境での使用には注意が必要です。

**出典**:

- TheWeeklyChallenge: Design Pattern Factory - https://theweeklychallenge.org/blog/design-pattern-factory/
- Perldoc: perlclass - https://perldoc.perl.org/perlclass

**信頼度**: 高(公式ドキュメント準拠)

---

### 3.3 実用的な例: JSON-RPC Request生成(実際のプロジェクトより)

**要点**:

実際のプロジェクトで使われているFactory Methodパターンの実装例として、JSON-RPC Requestオブジェクトの生成を紹介します。

```perl
package JsonRpc::Request;
use Moo;
use Types::Standard qw(Maybe Str Int ArrayRef HashRef InstanceOf);

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has method => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::MethodName'],
    required => 1,
);

has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef],
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
);

# Factory Method: ハッシュからRequestオブジェクトを生成
sub from_hash {
    my ($class, $hash) = @_;
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        method  => JsonRpc::MethodName->new(value => $hash->{method}),
        params  => $hash->{params},
        id      => $hash->{id},
    );
}

1;
```

**使用例**:

```perl
use JsonRpc::Request;

# JSONから受け取ったハッシュリファレンス
my $json_data = {
    jsonrpc => '2.0',
    method  => 'sum',
    params  => [1, 2, 3],
    id      => 1,
};

# Factory Methodで生成
my $request = JsonRpc::Request->from_hash($json_data);

# バリデーション済みのオブジェクトとして使用
say $request->method->value;  # 出力: sum
```

**解説**:

- `from_hash`がFactory Methodとして機能
- 生成時に各フィールドのバリデーションが自動実行される
- クライアントは内部のバリデーションロジックを知る必要がない

**出典**:

- 内部リンク: /2025/12/25/234500/ (JSON-RPC Request/Response実装記事)

**信頼度**: 高(実装済みプロジェクトコード)

---

## 4. Factory Methodパターンの利点(メリット)

**要点**:

Factory Methodパターンには以下の明確な利点があります:

### メリット1: オブジェクト生成ロジックのカプセル化

**詳細**:
- 複雑な生成処理を一箇所に集約できる
- クライアントコードが「どう作るか(How)」を知る必要がない
- 生成ロジックの変更が容易

**根拠**: 
生成処理がFactoryメソッド内にカプセル化されるため、依存関係の管理や初期化処理の変更が局所化されます。

---

### メリット2: 疎結合(Loose Coupling)

**詳細**:
- クライアントコードは具体クラスへの依存を持たない
- Productインターフェースのみに依存するため、実装の変更に強い
- テスト時にモックオブジェクトへの差し替えが容易

**根拠**: 
クライアントがConcreteProductを直接インスタンス化しないため、依存関係が抽象(インターフェース)に向けられます。

---

### メリット3: 拡張性の向上(オープン・クローズドの原則)

**詳細**:
- 新しいConcreteProductを追加する際、既存コードの変更が不要
- サブクラスを追加するだけで機能拡張が可能
- 既存のクラスやクライアントコードは変更せずに済む("Open for extension, Closed for modification")

**根拠**: 
新しい製品タイプは新しいConcreteCreatorとConcreteProductのペアを追加するだけで実現でき、既存のCreatorクラスやクライアントコードには影響を与えません。

---

### メリット4: コードの再利用性

**詳細**:
- 共通の生成ロジックを親クラス(Creator)に記述できる
- サブクラスは差分だけを実装すれば良い
- 同じFactory Methodを複数箇所から呼び出せる

**根拠**: 
Template Methodパターンと組み合わせることで、生成前後の共通処理を親クラスで定義し、具体的な生成部分だけをサブクラスで実装できます。

---

### メリット5: テスタビリティの向上

**詳細**:
- テスト時にモックFactoryを注入しやすい
- 具体実装への依存がないため、スタブやモックオブジェクトへの差し替えが容易
- 単体テストの独立性を保ちやすい

**根拠**: 
依存性注入(DI)と組み合わせることで、テスト環境では本番のFactoryの代わりにMock Factoryを注入できます。

---

**出典**:

- GeeksforGeeks: Factory method Design Pattern - https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/
- DEV Community: Factory Design Pattern in Java - https://dev.to/zeeshanali0704/factory-design-pattern-in-java-a-complete-guide-dgj
- Design Patterns Mastery: Factory Method Pattern Advantages - https://designpatternsmastery.com/5/2/2/5/

**信頼度**: 高

---

## 5. Factory Methodパターンの欠点(デメリット)

**要点**:

Factory Methodパターンには以下のデメリットも存在します。適用時には利点と欠点のバランスを考慮する必要があります。

### デメリット1: クラス数の増加

**詳細**:
- 製品タイプごとにConcreteCreatorとConcreteProductのペアが必要
- 小規模プロジェクトではクラス数が過度に増え、構造が複雑化
- ファイル数の増加により、プロジェクト構造の把握が困難になる可能性

**影響度**: 
製品タイプが5個以上になると、クラス数が10個以上に膨れ上がる可能性があります。

**根拠**: 
各ConcreteProductに対応するConcreteCreatorを作成する必要があるため、最低でも製品タイプ数の2倍のクラスが必要になります。

---

### デメリット2: 継承への依存

**詳細**:
- Factory Methodパターンは継承を前提とした設計
- 継承階層が深くなると保守性が低下
- コンポジションを好む設計思想とは相反する
- 多重継承の問題が発生する可能性(言語による)

**根拠**: 
GoFのFactory Methodパターンは「サブクラスがfactoryMethod()をオーバーライドする」という継承ベースの構造です。継承よりコンポジションを推奨する現代的な設計思想とは必ずしも一致しません。

---

### デメリット3: ボイラープレートコードの増加

**詳細**:
- 単純なオブジェクト生成のために多くのボイラープレートコードが必要
- インターフェース定義、抽象クラス、実装クラスなど、定型的なコードが増える
- 小規模な用途では通常の`new`で済むところを過剰に抽象化してしまう

**具体例**: 
単に`Circle->new()`で済むところを、ShapeFactory、Shapeインターフェース、Creatorクラスなどを用意する必要があります。

---

### デメリット4: 過剰設計(オーバーエンジニアリング)のリスク

**詳細**:
- 拡張性が不要な場面で適用すると、無駄な複雑さを招く
- YAGNI原則(You Aren't Gonna Need It)に反する可能性
- 設計の意図が理解されないまま形式的に導入されるとアンチパターン化

**根拠**: 
Factory Methodパターンは「将来の拡張性」を見越した設計ですが、その拡張が実際には発生しない場合、複雑さだけが残ります。

---

### デメリット5: 初期学習コストの高さ

**詳細**:
- デザインパターンに不慣れなチームメンバーにとっては理解が難しい
- パターンの意図を理解しないまま使用すると誤用につながる
- ドキュメントやコメントでの説明が必須

**根拠**: 
Factory Methodパターンは抽象度が高く、コードを読むだけではその意図が伝わりにくい場合があります。

---

**出典**:

- Design Patterns Mastery: Factory Method Pattern Limitations - https://designpatternsmastery.com/5/2/2/5/
- JavaTechOnline: Factory Method Design Pattern in Java - https://javatechonline.com/factory-method-design-pattern-in-java-analogy/
- Qiita: 【デザインパターン】ファクトリーメソッドパターン解説 - https://qiita.com/nozomi2025/items/4a68d12a1fc539b1a582

**信頼度**: 高

---

## 6. Factory Method vs Simple Factory vs Abstract Factory

**要点**:

Factory系のパターンは複数あり、混同されやすいため、違いを明確にします。

### 6.1 比較表

| 特徴 | Simple Factory | Factory Method | Abstract Factory |
|------|---------------|----------------|------------------|
| **分類** | GoFパターンではない(補助パターン) | GoF生成パターン | GoF生成パターン |
| **生成決定** | 一箇所に集中 | サブクラスに委譲 | ファミリー単位で委譲 |
| **拡張性(OCP)** | 低い(修正が必要) | 高い(サブクラス追加) | 最高(ファクトリー実装追加) |
| **継承** | 不要 | 必要 | インターフェースベース |
| **生成する製品** | 複数、無関連 | 複数、類似 | 複数、関連ファミリー |
| **クライアント依存** | Factoryクラスと製品 | Factory Methodの契約 | Abstract Factoryインターフェース |
| **典型的用途** | シンプルなケース | フレームワークフック | テーマ/UIツールキット |

---

### 6.2 Simple Factory(シンプルファクトリー)

**特徴**:
- 静的メソッドまたは単一クラスでオブジェクト生成を行う
- if/elseやswitch文で型を判定して生成
- 継承を使わない最もシンプルな形

**実装例(概念)**:

```perl
package CoffeeFactory;

sub make_coffee {
    my ($type) = @_;
    
    return Latte->new      if $type eq 'latte';
    return Espresso->new   if $type eq 'espresso';
    return Cappuccino->new if $type eq 'cappuccino';
    
    die "Unknown coffee type: $type\n";
}
```

**欠点**: 新しいコーヒータイプを追加するたびに`make_coffee`メソッドを修正する必要がある(OCPに違反)

---

### 6.3 Factory Method(ファクトリーメソッド)

**特徴**:
- 継承を使ってサブクラスに生成処理を委譲
- 各サブクラスが独自のfactoryMethod()を実装
- 拡張時に既存コードを変更せずにサブクラスを追加

**実装例(概念)**:

```perl
package CoffeeFactory;  # 抽象
use Moo;
sub make_coffee { die "Override me\n" }

package LatteFactory;
use Moo;
extends 'CoffeeFactory';
sub make_coffee { Latte->new }

package EspressoFactory;
use Moo;
extends 'CoffeeFactory';
sub make_coffee { Espresso->new }
```

---

### 6.4 Abstract Factory(抽象ファクトリー)

**特徴**:
- 関連する製品ファミリーをまとめて生成
- インターフェースベースで複数の製品を生成するメソッド群を持つ
- クロスプラットフォーム対応やテーマ切り替えに最適

**実装例(概念)**:

```perl
# ItalianCoffeeFactory
# - make_coffee() → Espresso
# - make_snack()  → ItalianBiscuit

# FrenchCoffeeFactory
# - make_coffee() → FrenchRoast
# - make_snack()  → Croissant
```

クライアントはItalianCoffeeFactoryまたはFrenchCoffeeFactoryを選び、一貫したスタイルのコーヒーとスナックを取得できます。

---

**出典**:

- Baeldung: Factory Method vs Factory vs Abstract Factory - https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory
- Stack Overflow: Differences between Abstract Factory and Factory - https://stackoverflow.com/questions/5739611/what-are-the-differences-between-abstract-factory-and-factory-design-patterns
- JavaThinking: Factory vs Factory Method vs Abstract Factory - https://www.javathinking.com/blog/design-patterns-factory-vs-factory-method-vs-abstract-factory/

**信頼度**: 高

---

## 7. 競合記事の分析

### 7.1 主要な競合・参考記事

| サイト名 | 言語 | 特徴 | URL |
|---------|------|------|-----|
| **Refactoring Guru** | 多言語(日本語あり) | 視覚的で分かりやすい、UML図豊富、多言語コード例 | https://refactoring.guru/design-patterns/factory-method |
| **GeeksforGeeks** | 英語 | 網羅的な解説、Java実装中心、インタビュー対策向け | https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/ |
| **Qiita (nozomi2025)** | 日本語 | Flutter/Android実例付き、初心者向け、構造図が丁寧 | https://qiita.com/nozomi2025/items/4a68d12a1fc539b1a582 |
| **Zenn (umibudou)** | 日本語 | 初心者向け入門記事、TypeScript実装例 | https://zenn.dev/umibudou/articles/93192b2d527ad9 |
| **TheWeeklyChallenge** | 英語 | Perl実装例(Moo/Object::Pad)、実用的 | https://theweeklychallenge.org/blog/design-pattern-factory/ |
| **IT専科** | 日本語 | Java実装、詳細な解説、企業研修向け | https://www.itsenka.com/contents/development/designpattern/factory_method.html |

---

### 7.2 競合記事の強み・弱み

#### Refactoring Guruの強み
- **視覚化**: UML図、シーケンス図が豊富で理解しやすい
- **多言語対応**: Java, Python, TypeScript, C++, PHPなど多数の実装例
- **実践的**: メリット・デメリット、使用場面が明確

#### GeeksforGeeksの強み
- **網羅性**: 定義から実装、応用例まで一貫して解説
- **インタビュー対策**: 就職面接で聞かれるポイントをカバー
- **Java中心**: Javaエコシステムでの適用例が充実

#### 日本語記事(Qiita/Zenn)の強み
- **日本語での丁寧な説明**: 初学者にも分かりやすい
- **具体的な実装例**: Flutter、Android、TypeScriptなど実践的
- **コミュニティ評価**: いいね数やコメントで品質が分かる

#### TheWeeklyChallengeの強み(Perl)
- **Perl実装**: MooやObject::Padを使った実装例
- **モダンPerl**: Perl 5.38の`class`構文の紹介
- **実用性**: 実際に動作するコード例

---

### 7.3 既存記事の問題点と本調査の差別化ポイント

#### 既存記事の問題点

1. **Perl実装例の不足**: ほとんどの記事がJava/C++/TypeScriptに偏っており、Perl実装は少ない
2. **抽象的な例が多い**: 「Document」「Shape」などの教科書的な例が中心で、実務での適用イメージが湧きにくい
3. **メリット偏重**: デメリットや適用すべきでない場面の言及が不足
4. **パターン間の比較不足**: Simple Factory、Factory Method、Abstract Factoryの違いが明確でない

#### 本調査ドキュメントの差別化ポイント

1. **Perl実装の充実**: Mooを使った実装例、Perl 5.38のclass構文、実際のプロジェクトコード(JSON-RPC)
2. **実用的な例**: JSON-RPC Request生成、通知システム、ドキュメント生成など
3. **バランスの取れた評価**: メリットとデメリットを同等に詳述し、適用すべきでない場面も明記
4. **日本語での包括的まとめ**: 定義、構造、実装、利点、欠点、競合比較を一貫して日本語で提供
5. **内部リンク戦略**: 既存のデザインパターン記事(Strategy、Singleton、Observerなど)との連携

---

## 8. 内部リンク候補の調査

### 8.1 関連記事(デザインパターン・オブジェクト指向)

以下は、`/content/post`配下に存在する関連記事の一覧です。

| カテゴリ | ファイルパス | タイトル(推定) | 内部リンク | 関連度 |
|---------|-------------|-----------------|-----------|--------|
| **デザインパターン概要** | `/content/warehouse/design-patterns-overview.md` | デザインパターン概要 | - | 高(Factory Methodを含む23パターンの概要) |
| **デザインパターン調査** | `/content/warehouse/design-patterns-research.md` | デザインパターン調査ドキュメント | - | 高(各パターンの詳細調査) |
| **Strategyパターン** | `/content/post/2025/12/30/164012.md` | 第12回-デザインパターンの世界へ(Mooディスパッチャーシリーズ) | `/2025/12/30/164012/` | 高(生成パターンと振る舞いパターンの違い) |
| **Factory適用例** | `/content/post/2025/12/30/164009.md` | 第9回-自動で選ぶ仕組みを作ろう(Factoryパターン) | `/2025/12/30/164009/` | 極高(Factoryパターンの実装例) |
| **Factory+値オブジェクト** | `/content/post/2025/12/25/234500.md` | JSON-RPC Request/Response実装 - 複合値オブジェクト設計 | `/2025/12/25/234500/` | 高(from_hashファクトリーメソッド) |
| **Moo OOP基礎** | `/content/post/2021/10/31/191008.md` | 第1回-Mooで覚えるオブジェクト指向プログラミング | `/2021/10/31/191008/` | 中(OOPの基礎、継承、ロール) |
| **Moose::Role** | `/content/post/2009/02/14/105950.md` | Moose::Roleが興味深い | `/2009/02/14/105950/` | 中(ロールパターン) |
| **Moo発表資料** | `/content/post/2016/02/21/150920.md` | よなべPerl で Moo について喋ってきました | `/2016/02/21/150920/` | 低(Mooの紹介) |

---

### 8.2 内部リンク戦略

Factory Methodパターンの記事を執筆する際、以下の内部リンクを活用すべきです:

#### 必須リンク(導入部・概要)
- デザインパターン概要(23パターンの分類)
- Strategyパターン(振る舞いパターンとの対比)

#### 実装例セクション
- JSON-RPC Request/Response実装(from_hashファクトリーメソッドの実例)
- 第9回-自動で選ぶ仕組みを作ろう(Factoryパターンの実装例)

#### 基礎知識セクション
- Mooで覚えるオブジェクト指向プログラミング(OOPの基礎)
- Moose::Roleが興味深い(ロールパターンの理解)

---

## 9. 技術的正確性担保のための情報源リスト

### 9.1 公式書籍(必読)

| 書籍名 | 著者 | ISBN | 備考 |
|-------|------|------|------|
| **Design Patterns: Elements of Reusable Object-Oriented Software** | Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides | 978-0201633610 | GoF原典、Factory Methodの定義元 |
| **Head First Design Patterns (2nd Edition)** | Eric Freeman, Elisabeth Robson | 978-1492078005 | 視覚的で理解しやすい、初心者向け |
| **Dive Into Design Patterns** | Alexander Shvets | - | Refactoring Guru著者、多言語対応 |

---

### 9.2 信頼性の高いWebリソース(英語)

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **Refactoring Guru** | https://refactoring.guru/design-patterns/factory-method | 視覚的、多言語コード例、UML図 |
| **GeeksforGeeks** | https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/ | 網羅的、Java実装、インタビュー対策 |
| **Wikipedia** | https://en.wikipedia.org/wiki/Factory_method_pattern | 中立的な定義、歴史的背景 |
| **Software Patterns Lexicon** | https://softwarepatternslexicon.com/mastering-design-patterns/creational-design-patterns/factory-method-pattern/ | 詳細な構造解説 |
| **Baeldung** | https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory | Factory系パターンの比較 |
| **Stack Overflow** | https://stackoverflow.com/questions/5739611/what-are-the-differences-between-abstract-factory-and-factory-design-patterns | コミュニティの実践的知見 |

---

### 9.3 日本語リソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **Qiita (nozomi2025)** | https://qiita.com/nozomi2025/items/4a68d12a1fc539b1a582 | Flutter/Android実装例、初心者向け |
| **Zenn (umibudou)** | https://zenn.dev/umibudou/articles/93192b2d527ad9 | TypeScript実装、入門記事 |
| **IT専科** | https://www.itsenka.com/contents/development/designpattern/factory_method.html | 詳細な日本語解説、企業研修向け |
| **trendsメディア** | https://trends.codecamp.jp/blogs/media/terminology518 | 初心者向け用語解説 |
| **Refactoring Guru(日本語版)** | https://refactoring.guru/ja/design-patterns/factory-method | 日本語化された視覚的解説 |

---

### 9.4 Perl実装関連リソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **TheWeeklyChallenge** | https://theweeklychallenge.org/blog/design-pattern-factory/ | Moo/Object::Pad実装例、Perl 5.38 class構文 |
| **Perldoc: perlclass** | https://perldoc.perl.org/perlclass | Perl 5.38公式ドキュメント |
| **Moo公式ドキュメント** | https://metacpan.org/pod/Moo | Mooの公式マニュアル |
| **Moose公式ドキュメント** | https://metacpan.org/pod/Moose | Mooseの公式マニュアル |

---

### 9.5 GitHub実装例(参考コード)

| リポジトリ | 言語 | URL | 特徴 |
|-----------|------|-----|------|
| **iluwatar/java-design-patterns** | Java | https://github.com/iluwatar/java-design-patterns | 90k+ stars、Factory Method含む全パターン |
| **faif/python-patterns** | Python | https://github.com/faif/python-patterns | 40k+ stars、Pythonでの実装 |
| **torokmark/design_patterns_in_typescript** | TypeScript | https://github.com/torokmark/design_patterns_in_typescript | TypeScript実装 |
| **RefactoringGuru/design-patterns-typescript** | TypeScript | https://github.com/RefactoringGuru/design-patterns-typescript | Refactoring Guru公式サンプル |

---

## 10. 調査結果のサマリー

### 10.1 主要な発見

1. **Factory Methodは生成パターンの基礎**: Singleton、Abstract Factoryと並ぶGoFの代表的な生成パターン
2. **拡張性とトレードオフ**: クラス数増加というコストと引き換えに、高い拡張性を実現
3. **Perlでの実装**: MooのロールやPerl 5.38のclass構文で柔軟に実装可能
4. **実務での頻出**: フレームワーク設計、プラグイン機構、データアクセス層などで広く使用
5. **パターン間の違いの重要性**: Simple Factory、Factory Method、Abstract Factoryは目的と構造が異なる

---

### 10.2 技術記事執筆時の推奨構成

Factory Methodパターンの記事を執筆する際、以下の構成を推奨します:

1. **導入**: デザインパターンの位置づけ(GoF生成パターン)
2. **問題提起**: なぜFactory Methodが必要なのか(具体例を用いて)
3. **パターンの定義**: 4つの要素(Product, ConcreteProduct, Creator, ConcreteCreator)
4. **実装例**: Perlでの具体的なコード(Moo、Perl 5.38)
5. **メリット・デメリット**: バランスの取れた評価
6. **使い分け**: Simple Factory、Abstract Factoryとの違い
7. **実践例**: 実際のプロジェクト(JSON-RPC)での適用
8. **まとめ**: いつ使うべきか、いつ使うべきでないか

---

### 10.3 今後の調査が必要な領域

- **パターンの組み合わせ**: Factory Method + Singleton、Factory Method + Template Method
- **アンチパターン**: Factory Methodの誤用例と対策
- **パフォーマンス**: オブジェクト生成コストの測定
- **関数型プログラミングとの関係**: 関数型言語でのFactory Methodの扱い

---

## 11. 参考文献・参考サイト(統合版)

### 11.1 GoF原典・定番書籍

| 書籍名 | 著者 | ISBN/ASIN | 備考 |
|-------|------|-----------|------|
| **Design Patterns: Elements of Reusable Object-Oriented Software** | Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides | ISBN: 978-0201633610 | GoF原典、Factory Methodの定義元 |
| **Head First Design Patterns (2nd Edition)** | Eric Freeman, Elisabeth Robson | ISBN: 978-1492078005 | 初心者向け、視覚的解説 |
| **Dive Into Design Patterns** | Alexander Shvets | - | Refactoring Guru著者、多言語対応 |

### 11.2 Web情報源(英語)

| URL | 特徴 | 信頼度 |
|-----|------|--------|
| https://refactoring.guru/design-patterns/factory-method | 視覚的、UML図、多言語コード例 | 高 |
| https://www.geeksforgeeks.org/system-design/factory-method-for-designing-pattern/ | 網羅的、Java実装、インタビュー対策 | 高 |
| https://en.wikipedia.org/wiki/Factory_method_pattern | 中立的定義、歴史的背景 | 高 |
| https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory | Factory系パターン比較 | 高 |
| https://stackoverflow.com/questions/5739611/what-are-the-differences-between-abstract-factory-and-factory-design-patterns | コミュニティの実践知見 | 中〜高 |
| https://theweeklychallenge.org/blog/design-pattern-factory/ | Perl実装例(Moo、Object::Pad) | 高 |

### 11.3 Web情報源(日本語)

| URL | 特徴 | 信頼度 |
|-----|------|--------|
| https://qiita.com/nozomi2025/items/4a68d12a1fc539b1a582 | Flutter/Android実装例、初心者向け | 高 |
| https://zenn.dev/umibudou/articles/93192b2d527ad9 | TypeScript実装、入門記事 | 高 |
| https://www.itsenka.com/contents/development/designpattern/factory_method.html | 詳細な日本語解説、企業研修向け | 高 |
| https://refactoring.guru/ja/design-patterns/factory-method | 日本語化された視覚的解説 | 高 |

### 11.4 Perl関連リソース

| URL | 特徴 | 信頼度 |
|-----|------|--------|
| https://theweeklychallenge.org/blog/design-pattern-factory/ | Moo/Object::Pad実装例 | 高 |
| https://perldoc.perl.org/perlclass | Perl 5.38公式ドキュメント | 高 |
| https://metacpan.org/pod/Moo | Moo公式マニュアル | 高 |
| https://metacpan.org/pod/Moose | Moose公式マニュアル | 高 |

### 11.5 GitHub実装例

| リポジトリ | 言語 | URL | スター数 |
|-----------|------|-----|---------|
| iluwatar/java-design-patterns | Java | https://github.com/iluwatar/java-design-patterns | 90k+ |
| faif/python-patterns | Python | https://github.com/faif/python-patterns | 40k+ |
| torokmark/design_patterns_in_typescript | TypeScript | https://github.com/torokmark/design_patterns_in_typescript | 5k+ |

---

**調査完了日**: 2025年12月31日  
**調査者**: 調査・情報収集専門エージェント  
**信頼度総合評価**: 高(GoF原典、公式ドキュメント、著名技術サイトを複数参照)
