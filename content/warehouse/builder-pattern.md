---
date: 2026-01-17T17:51:52+09:00
description: 'Builderパターンに関する包括的な調査結果 - GoF定義、実装パターン、関連パターンとの比較を網羅'
draft: true
epoch: 1768672312
image: /favicon.png
iso8601: 2026-01-17T17:51:52+09:00
tags:
  - builder-pattern
  - design-patterns
  - gof
  - perl
  - object-oriented
title: Builderパターン調査ドキュメント
---

# Builderパターン調査ドキュメント

## 調査目的

GoFの「Builderパターン」についての包括的な調査を実施し、デザインパターン学習シリーズの企画のための基礎資料を作成する。

- **調査対象**: Builderパターンの定義、目的、実装手法、利点・欠点、関連パターン、PerlおよびCPANでの実装例
- **想定読者**: Perlプログラマー、デザインパターン学習者
- **調査実施日**: 2026年01月17日

---

## 1. 概要

### 1.1 Builderパターンの定義

**要点**:

- GoF（Gang of Four）の23デザインパターンの1つで、生成に関するパターン（Creational Pattern）に分類される
- 複雑なオブジェクトの生成過程を、その表現から分離し、同じ生成プロセスで異なる表現を作成できるようにする
- オブジェクトを段階的に構築することで、構築の柔軟性と可読性を向上させる
- 「どう作るか」に焦点を当てたパターンであり、構築手順と完成品を分離する

**根拠**:

- GoF『Design Patterns: Elements of Reusable Object-Oriented Software』で定義された23パターンの1つ
- "separates the construction of a complex object from its representation" という原則的定義がある
- 多数の引数や複数の初期化手順が必要な場合に、コンストラクタやファクトリだけだとコードが煩雑になりやすい問題を解決する

**出典**:

- GeeksforGeeks: Builder Design Pattern - https://www.geeksforgeeks.org/system-design/builder-design-pattern/
- DEV Community: The Builder Design Pattern - https://dev.to/paulund/the-builder-design-pattern-1986
- Qiita: 【デザインパターン】GoF 23パターンを学んでみる 〜Builder編〜 - https://qiita.com/Pentaro256/items/230f40780f785264607e
- Wikipedia (日本語): Builder パターン - https://ja.wikipedia.org/wiki/Builder_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3

**信頼度**: 10/10（GoF公式定義および複数の信頼できる技術サイトで一致）

---

### 1.2 登場するクラス/役割

**要点**:

Builderパターンは以下の4つの役割で構成される:

| 役割 | 責務 | 特徴 |
|------|------|------|
| **Product（生成物）** | 構築される複雑なオブジェクト | 様々なパーツから構成される最終成果物 |
| **Builder（ビルダー）** | Productのパーツを生成する抽象インターフェース | 各パーツを作成するメソッドを定義 |
| **ConcreteBuilder（具象ビルダー）** | Builderインターフェースの具体実装 | 実際の生成方法を実装し、Productを返すメソッドを提供 |
| **Director（監督）** | Builderを使用して構築プロセスを制御 | 構築手順の順序を知っているが、Productの詳細は知らない |

**根拠**:

- GoFのBuilder Pattern構造図に基づく標準的な役割分担
- Directorは必須ではなく、現代の実装ではFluent Interfaceとして省略されることも多い
- 各役割の責務が明確に分離されており、単一責任の原則（SRP）に準拠している

**出典**:

- Rookie Nerd: Builder Design Pattern - https://rookienerd.com/tutorial/design-pattern/builder-design-pattern
- Visual Paradigm: Builder Pattern Tutorial - https://www.visual-paradigm.com/tutorials/builderpattern.jsp
- Software Patterns Lexicon: Director and Builder Roles - https://softwarepatternslexicon.com/java/creational-patterns/builder-pattern/director-and-builder-roles/
- ソフトウェア開発日記: Builderパターンとは - https://lightgauge.net/journal/object-oriented/builder-pattern

**信頼度**: 9/10（GoF準拠の標準的な構造、現代的変形あり）

---

### 1.3 解決する問題

**要点**:

- **Telescoping Constructor（テレスコーピングコンストラクタ）アンチパターン**: 多数のパラメータを持つコンストラクタのオーバーロードが増殖する問題
- 複雑なオブジェクトの初期化における可読性の低下
- 必須パラメータと任意パラメータの混在による引数順序の混乱
- オブジェクト生成ロジックの重複とメンテナンス性の低下

**根拠**:

Telescoping Constructorの例（問題のあるコード）:
```java
public class Product {
    public Product(String name) { this(name, 0); }
    public Product(String name, int price) { this(name, price, "Uncategorized"); }
    public Product(String name, int price, String category) { 
        this(name, price, category, "Unknown"); 
    }
    public Product(String name, int price, String category, String manufacturer) {
        // 実際の初期化
    }
}
```

この問題をBuilderパターンで解決すると、パラメータの順序を気にせず、必要なものだけを設定できる。

**出典**:

- Code with Shabib: Dealing with Telescopic Constructors - https://www.codewithshabib.com/dealing-with-telescopic-constructors-anti-pattern/
- 1kevinson: Avoid Using Too Many Constructors - https://www.1kevinson.com/avoid-using-too-much-constructors-and-improve-your-code-clarity-with-builder-pattern/
- PW Skills: Builder Pattern in C++ - https://pwskills.com/blog/builder-pattern-in-c-design-patterns/

**信頼度**: 10/10（広く認識されている問題とその解決策）

---

## 2. 用途と実例

### 2.1 具体的な利用シーン

**要点**:

| 利用シーン | 説明 | 具体例 |
|-----------|------|--------|
| **複雑なオブジェクト構築** | 多数のフィールドや相互依存するパーツを持つオブジェクト | HTTPリクエスト、コンピュータ設定（CPU、RAM、GPU等）、食事注文（ピザ、ドリンク、デザート） |
| **イミュータブルオブジェクト** | 一度生成したら変更不可なオブジェクト | Value Object、DTO（Data Transfer Object）、スレッドセーフが求められるクラス |
| **Fluent Interface** | メソッドチェーンによる宣言的なオブジェクト構築 | クエリビルダー（SQL）、テスト用アサーション、REST APIクライアント |
| **段階的な構築が必要** | 構築プロセスに順序や条件分岐がある | ドキュメント生成（HTML、PDF）、UI部品（ダイアログ、フォーム） |

**根拠**:

- イミュータブルオブジェクトの場合、Builderはミュータブルだが、build()メソッドで最終的に不変なProductを返す
- Fluent Interfaceでは、各メソッドが`this`を返すことでメソッドチェーンを実現
- 検証が必要な場合、build()メソッド内で必須パラメータのチェックを行える

**出典**:

- Baeldung: Implement the Builder Pattern in Java - https://www.baeldung.com/java-builder-pattern
- Initgrep: Explore different use-cases for builder pattern in Java - https://www.initgrep.com/posts/design-patterns/when-to-use-builder-pattern
- HowToDoInJava: Java Builder Pattern - https://howtodoinjava.com/design-patterns/creational/builder-pattern-in-java/

**信頼度**: 9/10（実際のプロジェクトでの使用例が豊富）

---

### 2.2 有名なライブラリ/フレームワークでの使用例

**要点**:

#### Java
- **Lombok**: `@Builder`アノテーションでビルダーコードを自動生成
- **Spring Framework**: `RestTemplateBuilder`, `BeanDefinitionBuilder`, `WebClient.builder()`
- **Java 11+**: `HttpRequest.newBuilder()`による標準HTTPクライアント
- **Jackson**: ObjectMapperによるJSON構築

#### C#
- **ASP.NET**: `HttpRequestMessage`のFluent API
- **Entity Framework Core**: Fluent APIによるモデル設定
- **Microsoft Extensions**: `HostBuilder`, `WebHostBuilder`

#### Python
- **SQLAlchemy**: `query(User).filter_by(...).order_by(...)`のようなクエリビルダー
- **Requests**: `requests.Request()`オブジェクトの段階的構築

**根拠**:

Lombokの例:
```java
@Builder
public class Post {
    private String title;
    private String text;
}

// 使用例
Post post = Post.builder()
    .title("My Title")
    .text("Content")
    .build();
```

Spring Frameworkの例:
```java
RestTemplate restTemplate = new RestTemplateBuilder()
    .setConnectTimeout(Duration.ofSeconds(5))
    .setReadTimeout(Duration.ofSeconds(10))
    .build();
```

**出典**:

- Javatechonline: Builder Design Pattern In Java - https://javatechonline.com/builder-design-pattern-in-java-guide-examples/
- DotNetTutorials: Real-Time Examples of the Builder Design Pattern in C# - https://dotnettutorials.net/lesson/builder-design-pattern-real-time-example/
- DEV Community: Builder Pattern in C# - https://dev.to/devesh_omar_b599bc4be3ee7/builder-pattern-in-c-practical-implementation-and-examples-451n

**信頼度**: 9/10（公式ドキュメントおよび実装例が確認可能）

---

## 3. PerlにおけるBuilderパターンの実装

### 3.1 Mooを使った実装

**要点**:

MooはPerlのモダンなオブジェクト指向フレームワークで、軽量かつ高速。Builderパターンの実装に適している。

```perl
# Product.pm
package Product;
use Moo;

has name        => (is => 'ro');
has description => (is => 'ro');
has price       => (is => 'ro');

1;
```

```perl
# ProductBuilder.pm
package ProductBuilder;
use Moo;

has _name        => (is => 'rw');
has _description => (is => 'rw');
has _price       => (is => 'rw');

sub name        { my ($self, $val) = @_; $self->_name($val); $self }
sub description { my ($self, $val) = @_; $self->_description($val); $self }
sub price       { my ($self, $val) = @_; $self->_price($val); $self }

sub build {
    my ($self) = @_;
    require Product;
    return Product->new(
        name        => $self->_name,
        description => $self->_description,
        price       => $self->_price,
    );
}

1;
```

**使用例**:
```perl
use ProductBuilder;

my $builder = ProductBuilder->new;
my $product = $builder->name('Keyboard')
                      ->description('Mechanical keyboard')
                      ->price(120)
                      ->build;

print $product->name; # Keyboard
```

**根拠**:

- Mooは`has`によるアトリビュート定義、`is => 'ro'`で読み取り専用属性を実現
- Builderのメソッドは`$self`を返すことでメソッドチェーンを可能にする
- Productは`ro`（読み取り専用）属性のみを持ち、イミュータブルなオブジェクトとなる

**出典**:

- MetaCPAN: Moo - https://metacpan.org/pod/Moo
- Perl Maven: OOP with Moo - https://perlmaven.com/oop-with-moo

**信頼度**: 10/10（公式ドキュメントに基づく実装）

---

### 3.2 Mooseを使った実装

**要点**:

Mooseはより機能豊富なメタプログラミング機能を持つが、実装パターンはMooとほぼ同じ。

```perl
# Product.pm
package Product;
use Moose;

has name        => (is => 'ro');
has description => (is => 'ro');
has price       => (is => 'ro');

1;
```

```perl
# ProductBuilder.pm
package ProductBuilder;
use Moose;

has _name        => (is => 'rw');
has _description => (is => 'rw');
has _price       => (is => 'rw');

sub name        { my ($self, $val) = @_; $self->_name($val); $self }
sub description { my ($self, $val) = @_; $self->_description($val); $self }
sub price       { my ($self, $val) = @_; $self->_price($val); $self }

sub build {
    my ($self) = @_;
    require Product;
    return Product->new(
        name        => $self->_name,
        description => $self->_description,
        price       => $self->_price,
    );
}

1;
```

**根拠**:

- MooseはMooよりも重いが、型制約（`isa => 'Int'`など）、ロール（Roles）、メソッド修飾子（around, before, after）などの高度な機能を提供
- `builder => '_build_something'`オプションで遅延初期化やカスタムビルドロジックを実装可能
- CPAN上のMooseXモジュール群による拡張機能が豊富

**出典**:

- MetaCPAN: Moose - https://metacpan.org/pod/Moose
- CPANdoc: Moose - https://cpandoc.grinnz.com/Moose
- Perl Maven: Object Oriented Perl using Moose - https://perlmaven.com/object-oriented-perl-using-moose

**信頼度**: 10/10（公式ドキュメント）

---

### 3.3 CPANモジュールでの使用例

**要点**:

- Moo/Mooseともに、`builder`オプションを使った属性レベルのビルダーメソッドをサポート
- 完全なBuilderパターン専用のCPANモジュールは少ないが、各フレームワークの機能で実現可能
- 実際のプロジェクトでは、必要に応じてカスタムBuilderクラスを作成することが一般的

**仮定**:

- CPAN上に「Builder Pattern」専用の汎用モジュールは存在しない可能性が高い（検索で確認できず）
- 各プロジェクトの要件に応じて、Moo/Mooseの機能を活用してカスタム実装することが推奨される

**出典**:

- Kablamo: How to Moo - http://kablamo.org/slides-intro-to-moo/

**信頼度**: 7/10（CPANの直接的なBuilderモジュールについては情報が限定的）

---

## 4. 利点・欠点

### 4.1 メリット

**要点**:

| メリット | 説明 | 具体例 |
|---------|------|--------|
| **可読性の向上** | パラメータの意味が明確で、コードが自己文書化される | `builder.name("John").age(30).build()`のように意図が明確 |
| **柔軟性** | 必須パラメータと任意パラメータを自由に組み合わせられる | HTTPリクエストのヘッダーやクエリパラメータの動的設定 |
| **イミュータビリティ** | 完成したオブジェクトを不変にできる | スレッドセーフなValue Objectの実装 |
| **構築と表現の分離** | 同じビルダーで異なる表現のオブジェクトを生成可能 | ConcreteBuilderを切り替えることで別のフォーマット生成 |
| **メンテナンス性** | パラメータの追加・削除が既存コードに影響しにくい | 新しい任意パラメータを追加してもクライアントコードが壊れない |
| **検証の集約** | build()メソッドで統一的にバリデーション実行 | 必須パラメータのチェックや値の整合性検証 |

**根拠**:

- Fluent Interfaceにより、メソッド名がパラメータの役割を示すため、IDEの補完も効きやすい
- Builderクラス自体はミュータブルだが、生成されるProductはイミュータブルにできる
- 構築ロジックがBuilderに集約されるため、DRY原則に準拠

**出典**:

- Software Patterns Lexicon: Builder Pattern - https://softwarepatternslexicon.com/mastering-design-patterns/creational-design-patterns/builder-pattern/
- DEV Community: Builder Design Pattern in Java - https://dev.to/priyankbhardwaj1199/builder-design-pattern-in-java-cleaning-up-the-mess-3hl3
- BradCypert.com: The Builder Design Pattern - https://www.bradcypert.com/design-patterns-builder/

**信頼度**: 9/10（広く認識されているメリット）

---

### 4.2 デメリット

**要点**:

| デメリット | 説明 | 影響 | 対策 |
|-----------|------|------|------|
| **コード量の増加** | Builderクラスの追加によりボイラープレートが増える | 小規模プロジェクトでは冗長 | Lombokなどのコード生成ツールを利用 |
| **単純なケースでのオーバーキル** | 2-3個のパラメータならコンストラクタで十分 | 設計の複雑化 | パラメータが4つ以上の場合のみBuilderを検討 |
| **パフォーマンスコスト** | メソッドチェーンによる軽微なオーバーヘッド | 性能クリティカルな処理では影響あり | 必要に応じて直接コンストラクタ利用も検討 |
| **Builderのミュータビリティ** | Builderインスタンスの再利用時に副作用のリスク | スレッド間での共有時に問題 | Builderは使い捨てにする、または適切に初期化 |
| **コンパイルエラーの遅延** | 必須パラメータのチェックがbuild()時まで遅延 | ランタイムエラーのリスク | build()メソッドで厳密なバリデーション実装 |

**根拠**:

- 3つ以下のパラメータなら通常のコンストラクタの方がシンプル
- Builderクラスの追加により、クラス数が増え、プロジェクト構造が複雑化する可能性
- 静的型付け言語でも、必須パラメータの設定忘れをコンパイル時に検出できない場合がある

**出典**:

- Software Engineering Stack Exchange: Is it a good idea to use Builder everywhere? - https://softwareengineering.stackexchange.com/questions/419403/is-it-a-good-or-a-bad-idea-to-use-the-builder-pattern-everywhere
- Wikipedia: Builder pattern - https://en.wikipedia.org/wiki/Builder_pattern
- springcavaj: Builder - A Creational Design Pattern - https://springcavaj.com/builder/

**信頼度**: 8/10（実務での経験に基づく認識）

---

## 5. 関連パターン

### 5.1 Factory Methodパターンとの違い

**要点**:

| 観点 | Builder | Factory Method |
|------|---------|----------------|
| **目的** | 複雑なオブジェクトの段階的構築 | サブクラスに生成ロジックを委譲 |
| **焦点** | 「どう作るか」（構築プロセス） | 「何を作るか」（インスタンス化の決定） |
| **生成物** | 1つの複雑なオブジェクト | 単一のシンプルなオブジェクト |
| **構築手順** | 複数ステップ、順序制御あり | 1メソッド、1生成 |
| **柔軟性** | 同じプロセスで異なる表現 | サブクラスごとに異なるクラス生成 |

**根拠**:

- Factory Methodは「どのクラスをインスタンス化するか」の決定に焦点
- Builderは「既に決まっているクラスをどう組み立てるか」に焦点
- 両者は組み合わせ可能（Builderの構築ステップ内でFactory Methodを使用）

**出典**:

- GeeksforGeeks: Differences Between Abstract Factory and Factory Design Patterns - https://www.geeksforgeeks.org/system-design/differences-between-abstract-factory-and-factory-design-patterns/
- Baeldung: Factory Method vs. Factory vs. Abstract Factory - https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory
- Stack Overflow: What is the difference between Builder and Factory? - https://stackoverflow.com/questions/757743/what-is-the-difference-between-builder-design-pattern-and-factory-design-pattern

**信頼度**: 9/10（複数の信頼できる資料で一致）

---

### 5.2 Abstract Factoryパターンとの違い

**要点**:

| 観点 | Builder | Abstract Factory |
|------|---------|------------------|
| **目的** | 複雑なオブジェクトの段階的構築 | 関連オブジェクト群の生成 |
| **生成対象** | 単一の複雑なオブジェクト | 関連する複数のオブジェクト（ファミリー） |
| **構築方法** | 段階的な組み立て | 一括生成（各factory methodで1つずつ） |
| **使用場面** | カスタマイズ可能な設定オブジェクト | OS別UIコンポーネント（Button, Menu, Windowのセット） |

**根拠**:

- Abstract Factoryは「製品ファミリー」の生成に特化（例: Windows用UI、Mac用UI）
- Builderは単一の複雑な製品を段階的に構築
- Abstract Factoryは複数のfactory methodを持ち、それぞれが異なる製品を返す

**出典**:

- W3Reference: Abstract Factory vs Builder Pattern - https://www.w3reference.com/software-design-patterns/abstract-factory-vs-builder-pattern-making-the-right-choice/
- Code Genes: Factory vs Abstract Factory Pattern - https://www.codegenes.net/blog/what-is-the-difference-in-case-of-intent-and-application-between-these-two-patterns/
- Refactoring Guru: Factory Comparison - https://refactoring.guru/design-patterns/factory-comparison

**信頼度**: 9/10（標準的な比較観点）

---

### 5.3 Telescoping Constructorアンチパターンとの関係

**要点**:

- **Telescoping Constructor**: コンストラクタのオーバーロードが無秩序に増殖するアンチパターン
- Builderパターンは、このアンチパターンの直接的な解決策として提案された
- 以下のような問題を解決:
  - 引数の順序を間違えやすい
  - 同じ型のパラメータが複数あると、順序の混乱が発生
  - 任意パラメータのバリエーションごとにコンストラクタを作る必要
  - 可読性が著しく低下

**根拠**:

Telescoping Constructorの問題例:
```java
new Product("Laptop", 1200, "Electronics", "Dell", "USA", true, 2);
// 何が何だか分からない...
```

Builderでの解決:
```java
new Product.Builder()
    .name("Laptop")
    .price(1200)
    .category("Electronics")
    .manufacturer("Dell")
    .origin("USA")
    .available(true)
    .warrantyYears(2)
    .build();
// 意図が明確！
```

**出典**:

- Samuel Tambunan's Blog: Builder pattern - https://samueltambunan.com/posts/2024/builder-pattern-for-parameters/
- Design Patterns for All: Builder - https://design-patterns-for-all.readthedocs.io/en/java/creational/Builder/
- Captain Debug's Blog: The Telescoping Constructor (Anti)Pattern - https://www.captaindebug.com/2011/05/telescoping-constructor-antipattern

**信頼度**: 10/10（広く認識されている関係性）

---

## 6. 競合記事分析

### 6.1 日本語記事

**要点**:

| サイト/記事 | URL | 特徴 |
|-----------|-----|------|
| Qiita | https://qiita.com/Pentaro256/items/230f40780f785264607e | GoF 23パターンの1つとして解説、実装例あり |
| nqou.net | https://www.nqou.net/warehouse/builder-pattern/ | 本調査ドキュメント（既存の場合は更新対象） |
| ソフトウェア開発日記 | https://lightgauge.net/journal/object-oriented/builder-pattern | GoF準拠の構造説明、Originator-Memento-Caretaker構造との比較 |
| 株式会社一創 | https://www.issoh.co.jp/tech/details/6334/ | 基本概念と特徴の解説 |
| Wikipedia (日本語) | https://ja.wikipedia.org/wiki/Builder_%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3 | 公式構造の説明、各プログラミング言語での実装例 |
| Programming TIPS! | https://programming-tips.jp/archives/a3/23/index.html | Java実装例と図解 |

**根拠**:

- 日本語記事は基本的な定義と構造の説明が中心
- Perl/Moo/Mooseに特化した詳細記事は少ない
- 実践的なユースケースやアンチパターンとの関係まで踏み込んだ記事は限定的

**信頼度**: 8/10（主要な日本語リソースを網羅）

---

### 6.2 英語記事

**要点**:

| サイト/記事 | URL | 特徴 |
|-----------|-----|------|
| GeeksforGeeks | https://www.geeksforgeeks.org/system-design/builder-design-pattern/ | 包括的な解説、実装例、利点・欠点 |
| Baeldung | https://www.baeldung.com/java-builder-pattern | Java実装の詳細、Immutabilityとの関係 |
| Refactoring Guru | https://refactoring.guru/design-patterns/factory-comparison | Factory系パターンとの比較 |
| DEV Community | https://dev.to/paulund/the-builder-design-pattern-1986 | 実践的な使い方、コード例 |
| Wikipedia (英語) | https://en.wikipedia.org/wiki/Builder_pattern | 公式定義、歴史的背景 |
| Stack Overflow | https://stackoverflow.com/questions/757743/ | Builder vs Factory の議論 |

**根拠**:

- 英語記事は実装例、ユースケース、パターン比較が豊富
- LombokやSpring Frameworkなどの具体的なライブラリ使用例が充実
- Telescoping Constructorアンチパターンとの関係性が詳しく解説されている

**信頼度**: 9/10（信頼性の高い技術サイトを網羅）

---

## 7. 内部リンク調査

### 7.1 関連する既存記事

**要点**:

| 記事タイトル | リンク | 関連性 |
|-------------|--------|--------|
| Moo/Moose - モダンなPerlオブジェクト指向プログラミング | /2025/12/11/000000/ | PerlでのOOP基礎、Moo/Mooseの使い方（Builderパターン実装に必須） |
| 第6回-これがPrototypeパターンだ！ - mass-producing-monsters | /2026/01/17/004437/ | 生成パターンの1つPrototypeとBuilderの比較に有用 |
| 【目次】PerlとMooでモンスター軍団を量産してみよう | /2026/01/17/004454/ | Prototypeパターン解説シリーズ（Factory Methodとの違いを学べる） |
| レート制限シナリオを追加しよう | /2026/01/17/132337/ | Mooによるクラス設計、OCP原則（Builderでも重要） |
| 偽APIの最小レスポンスを作ろう | /2026/01/17/132155/ | PerlとMooでのオブジェクト構築実例 |
| 完成した攻撃ツールを振り返り - Iteratorパターンという武器 | /2026/01/14/004232/ | デザインパターンシリーズ、設計思想の理解 |
| 第10回-これがMementoパターンだ！ | /2026/01/13/233533/ | GoFデザインパターンシリーズ、CommandパターンとMementoの違い |
| 第3回-何度も見るなら貯めたい - Mooで作るゴーストギャラリー・ビューワ | /2026/01/17/231027/ | Proxyパターン解説（構造パターンとの比較） |
| 第12回-完成！そして次へ | /2026/01/04/210453/ | Mooによるリファクタリング実例 |

**根拠**:

- grep検索で「Builder」「Factory」「デザインパターン」「Moo」「オブジェクト構築」に関連するファイルを抽出
- 特にMoo/Mooseを使ったデザインパターン実装シリーズとの関連性が高い
- 生成パターン（Creational Patterns）の他のパターンとの比較記事も関連

**出典**:

- 内部検索: `/home/runner/work/www.nqou.net/www.nqou.net/content/post` 配下のgrepによる抽出

**信頼度**: 10/10（実際のファイルパスを確認済み）

---

## 調査まとめ

### 主要な発見

1. **Builderパターンの本質**: 複雑なオブジェクトの「構築プロセス」と「完成品」を分離し、同じプロセスで異なる表現を作成できる生成パターン。Telescoping Constructorアンチパターンの直接的な解決策として認識されている。

2. **PerlでのBuilderパターン実装**: Moo/Mooseの`has`によるアトリビュート定義と、メソッドチェーンを活用することで、JavaやC#と同等のBuilderパターンを実装可能。`is => 'ro'`による不変性の実現が容易。

3. **Fluent Interfaceとの強い関連**: 現代的なBuilder実装では、Directorを省略し、Fluent Interface（メソッドチェーン）による宣言的な記述が主流。各builderメソッドが`$self`（または`this`）を返す設計。

4. **Factory系パターンとの違い**: Factory Method/Abstract Factoryは「何を作るか」、Builderは「どう作るか」に焦点。Builderは単一の複雑なオブジェクトを段階的に構築するのに対し、Abstract Factoryは関連オブジェクト群を一括生成する。

5. **実務での適用基準**: パラメータが4つ以上、または任意パラメータが多い場合にBuilderが有効。3つ以下なら通常のコンストラクタで十分なケースが多い。Lombok等のコード生成ツールによりボイラープレートを削減可能。

6. **内部リンクの豊富さ**: nqou.netには既にMoo/Mooseを使ったデザインパターン実装シリーズが多数存在し、Prototypeパターン、Mementoパターン、Iteratorパターンなどとの比較・関連付けが可能。

7. **CPANの状況**: Builder専用の汎用CPANモジュールは確認できず、各プロジェクトでMoo/Mooseの機能を活用してカスタム実装することが一般的。

---

**作成日**: 2026年01月17日  
**担当エージェント**: investigative-research  
**保存先**: `content/warehouse/builder-pattern.md`

---

## テンプレート使用時のチェックリスト

- [x] 各セクションに「要点」「根拠」「出典」「信頼度」が記載されているか
- [x] 出典URLが有効であるか
- [x] 信頼度の根拠が明確か（1-10の10段階評価）
- [x] 仮定がある場合は明記されているか
- [x] 内部リンク候補が調査されているか（grep で content/post を検索）
- [x] タグが英語小文字・ハイフン形式か
- [x] **提案・次のステップ・記事構成案・テーマ提案が含まれていないか**（調査ドキュメントは事実情報のみを記録し、提案は禁止）
