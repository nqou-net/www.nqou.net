---
date: 2025-12-31T08:43:00+09:00
description: Adapterパターンに関する包括的な調査結果。定義、用途、実装パターン、利点・欠点、実践的なサンプルを網羅的にまとめたドキュメント
draft: false
epoch: 1767138180
image: /favicon.png
iso8601: 2025-12-31T08:43:00+09:00
tags:
  - design-patterns
  - adapter
  - wrapper
  - gof
  - structural-patterns
title: Adapterパターン（デザインパターン）調査レポート
---

# Adapterパターン（デザインパターン）調査レポート

## 調査メタデータ

- **調査実施日**: 2025年12月31日
- **調査対象**: Adapterパターン（GoF構造パターン）
- **調査目的**: Adapterパターンの定義、実装方法、利点・欠点、実践的な活用例を包括的に整理する
- **想定読者**: デザインパターンを学び、実務で活用したいソフトウェアエンジニア

---

## 1. 概要

### 1.1 Adapterパターンとは何か

**要点**:

Adapter（アダプター）パターンは、互換性のないインターフェースを持つクラスやオブジェクト同士を接続できるようにするための構造パターンです。既存クラスの修正なしに、新しいインターフェースで既存の機能を再利用するための仕組みを提供します。

**根拠**:

- GoF書籍において「設計経験を記録し、再利用可能な形で伝える方法」として定義されている
- 異なるインターフェース間の橋渡し（Bridge）を行うことで、システムの拡張・統合を容易にする
- 既存コードへの変更を最小限に抑えつつ、新しい要件やインターフェース仕様に柔軟に対応する

**仮定**:

- 既存のコードが信頼性が高く、再利用したい機能を持っていることが前提
- インターフェースの不一致が問題となっている状況での適用

**出典**:

- Qiita: Adapter/Wrapperパターンとは？ - https://qiita.com/OtsukaTomoaki/items/21f083125f936c6f464b
- GeeksforGeeks: Adapter Design Pattern - https://www.geeksforgeeks.org/system-design/adapter-pattern/
- Refactoring Guru: Adapter - https://refactoring.guru/ja/design-patterns/adapter

**信頼度**: 高（公式書籍および著名な技術サイト）

---

### 1.2 構造パターンとしての位置づけ

**要点**:

Adapterパターンは、GoF（Gang of Four）が定義する23のデザインパターンの中で「構造パターン（Structural Patterns）」に分類されます。構造パターンは7種類あり、クラスやオブジェクトを組み合わせて、より大きな構造を形成するパターンです。

**構造パターン7種類**:

| パターン名 | 概要 |
|-----------|------|
| **Adapter** | 互換性のないインターフェースを持つクラスを、クライアントが期待するインターフェースに変換 |
| Bridge | 抽象部分と実装部分を分離し、それぞれが独立して変更可能にする |
| Composite | オブジェクトをツリー構造に組み立て、個別オブジェクトと複合オブジェクトを同一視 |
| Decorator | オブジェクトに動的に責任を追加し、サブクラス化の代替手段を提供 |
| Facade | サブシステムの複雑なインターフェース群に対して、統一された簡素なインターフェースを提供 |
| Flyweight | 多数の細粒度オブジェクトを効率的にサポートするため、オブジェクトを共有 |
| Proxy | 他のオブジェクトへのアクセスを制御する代理オブジェクトを提供 |

**根拠**:

- GoF書籍の構成がこの分類に基づいている
- 各分類は解決する問題の性質に対応している

**出典**:

- GeeksforGeeks: Gang of Four (GOF) Design Patterns - https://www.geeksforgeeks.org/system-design/gang-of-four-gof-design-patterns/
- content/warehouse/design-patterns-overview.md（本サイト内部リソース）

**信頼度**: 高

---

### 1.3 別名（Wrapper）について

**要点**:

Adapterパターンは、別名「Wrapper（ラッパー）パターン」とも呼ばれます。Wrapperは「あるクラスやオブジェクトを包み込むことで、インターフェースや振る舞いを変更・拡張する手法」の総称です。

**Wrapperとの関係**:

- Adapterは「互換性問題の解決（インターフェースの変換）」を担うWrapperの一種
- Decorator（機能追加）やFacade（複雑さの隠蔽）も広義のWrapperだが、目的が異なる
- Adapterは既存オブジェクトを「ラップ（包み込む）」して、新しいインターフェースを提供する

**根拠**:

- GoF書籍でも「Wrapper」という別名が言及されている
- 実装上、既存クラスのインスタンスを内部に持ち、それをラップする形になる

**出典**:

- Qiita: Adapter/Wrapperパターンとは？ - https://qiita.com/OtsukaTomoaki/items/21f083125f936c6f464b
- Java プログラミングTIPS: Adapter パターン - https://programming-tips.jp/archives/a2/94/index.html

**信頼度**: 高

---

## 2. 用途と目的

### 2.1 どのような問題を解決するか

**要点**:

Adapterパターンは、以下のような問題を解決します：

1. **インターフェースの不一致**: 既存のクラス（Adaptee）のインターフェースが、クライアントが期待するインターフェース（Target）と異なる場合
2. **既存資産の再利用**: 既存のコードを変更せずに、新しいシステムで活用したい場合
3. **システム統合**: レガシーシステムやサードパーティAPIを新しいシステムに統合する際のインターフェース互換性の問題

**問題の具体例**:

- 古いライブラリのAPIが現代的でない（メソッド名、引数の型、戻り値の形式が異なる）
- 複数のサードパーティAPIを統一的なインターフェースで扱いたい
- レガシーコードをリファクタリングせずに新システムと連携させたい

**根拠**:

- GoF書籍における「既存のクラスを新しいインターフェースで再利用する」という明確な目的
- 実務でのレガシーシステム統合やAPI統合のニーズに対応

**出典**:

- cstechブログ: Adapterパターンとは - https://cs-techblog.com/technical/adapter-pattern/
- GeeksforGeeks: Adapter Design Pattern - https://www.geeksforgeeks.org/system-design/adapter-pattern/

**信頼度**: 高

---

### 2.2 実際の使用シーン

**要点**:

Adapterパターンの典型的な使用シーンは以下の通りです：

**1. レガシーシステムのモダナイゼーション**

- 旧APIや旧ライブラリを新しいシステムに統合
- システムの段階的な移行（一部を新システムに置き換えながら、レガシー部分と共存）

**2. 異なるサードパーティ製ライブラリの統合**

- 外部サービスやデータフォーマット（XML/JSON/CSV等）が混在する場合に一貫したインターフェースで扱う
- 決済API（PayPay, Stripe, 楽天ペイなど）を統一インターフェースで管理

**3. 機能拡張や新旧APIの併用**

- 既存システムの一部を残しつつ、新しい振る舞いを部分的に導入する際

**4. システム間連携の強化**

- OSのデバイスドライバ、データベースコネクタなど、実世界の例でも用いられる

**具体例**:

```
// レガシー決済システム
OldPaymentSystem.makeOldPayment(amount, currency)

// 新システムのインターフェース
PaymentProcessor.process(amount, currency)

// Adapterで橋渡し
LegacyPaymentAdapter implements PaymentProcessor {
  process(amount, currency) {
    oldSystem.makeOldPayment(amount, currency)
  }
}
```

**出典**:

- Qiita: 【実践】Adapterパターンで実現するレガシーシステムとの共存戦略 - https://qiita.com/Tadataka_Takahashi/items/39b22d4e5e0e35eb52d2
- trends: Adapterパターンとは？ - https://trends.codecamp.jp/blogs/media/terminology830

**信頼度**: 高

---

### 2.3 他のパターンとの関係

**要点**:

Adapterパターンは、他の構造パターンと目的が似ているため、違いを理解することが重要です。

**主な構造パターンとの比較**:

| パターン名 | 主な目的 | 対象 | Adapterとの違い |
|-----------|---------|------|----------------|
| **Adapter** | インターフェース変換 | 個々のクラス | 互換性確保。既存資産の再利用 |
| **Bridge** | 機能/実装分離 | 抽象×実装 | 多種類の実装・拡張を独立して管理 |
| **Decorator** | 機能追加・動的拡張 | 個々のオブジェクト | 継承せず動的に機能拡張 |
| **Facade** | 簡易窓口・隠蔽 | サブシステム | 複雑なシステム全体の利用簡素化 |

**Adapterと他パターンの使い分け**:

- **Adapter vs Bridge**: Adapterは「既存の不一致を解消」、Bridgeは「設計時に抽象と実装を分離」
- **Adapter vs Decorator**: Adapterは「インターフェース変換」、Decoratorは「機能追加」
- **Adapter vs Facade**: Adapterは「個別クラスの変換」、Facadeは「複数クラスの統一窓口」

**根拠**:

- GoF書籍における各パターンの定義と目的の違い
- 実務での適用場面の違い

**出典**:

- Baeldung: Proxy, Decorator, Adapter and Bridge Patterns - https://www.baeldung.com/java-structural-design-patterns
- GeeksforGeeks: Difference Between the Facade, Proxy, Adapter, and Decorator Design Patterns - https://www.geeksforgeeks.org/system-design/difference-between-the-facade-proxy-adapter-and-decorator-design-patterns/
- Zenn: GoF デザインパターン 入門 ~構造に関するパターン~ - https://zenn.dev/giglancer/articles/9282ddc76b9e8a

**信頼度**: 高

---

## 3. 実装パターン

### 3.1 クラスアダプター（継承ベース）

**要点**:

クラスアダプターは、多重継承を利用して実装するパターンです。AdapterクラスがAdaptee（既存クラス）を継承し、Target（必要なインターフェース）を実装します。

**構造**:

```
Adapter extends Adaptee implements Target
```

**特徴**:

- **is-a関係**: 継承によるis-a（○○である）関係
- **全機能の継承**: AdapterクラスはAdapteeの全ての機能を引き継ぎます
- **実装がシンプル**: 直感的で高速
- **言語制約**: Java等の多重継承ができない言語では使いどころが限られる（Targetがinterfaceの場合、併用可能）
- **柔軟性**: 1対1でしか適用しにくい（柔軟性△）

**メリット**:

- 実装が直感的でシンプル
- メソッドのオーバーライドが容易
- パフォーマンスが良い（委譲のオーバーヘッドがない）

**デメリット**:

- 多重継承が必要（言語によっては不可能）
- 柔軟性が低い（1つのAdapteeにしか対応できない）
- 親クラスの変更の影響を受けやすい

**実装例（Java風の疑似コード）**:

```java
// Target（期待されるインターフェース）
interface Print {
    void printWeak();
    void printStrong();
}

// Adaptee（既存クラス）
class Banner {
    void showWithParen() {
        System.out.println("(Banner)");
    }
    void showWithAster() {
        System.out.println("*Banner*");
    }
}

// Adapter（継承型）
class PrintBanner extends Banner implements Print {
    public void printWeak() {
        showWithParen();  // 既存メソッドを利用
    }
    public void printStrong() {
        showWithAster();  // 既存メソッドを利用
    }
}
```

**出典**:

- Qiita: Adapterパターン - https://qiita.com/katsuya_tanaka/items/aacc219bf797400b638b
- サードペディア百科: Adapter パターンとは - https://pedia.3rd-in.co.jp/wiki/Adapter%20%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3
- IT専科: Adapter パターン - http://www.itsenka.com/contents/development/designpattern/adapter.html

**信頼度**: 高

---

### 3.2 オブジェクトアダプター（委譲ベース）

**要点**:

オブジェクトアダプターは、委譲（composition）を利用して実装するパターンです。AdapterクラスがAdapteeのインスタンスをフィールドとして保持し、Targetインターフェースを実装して、Adapteeのメソッドに委譲します。

**構造**:

```
Adapter implements Target {
    private Adaptee adaptee;
}
```

**特徴**:

- **has-a関係**: 委譲によるhas-a（○○を持つ）関係
- **部分的な機能利用**: AdapterクラスはAdapteeの一部の機能だけ使える
- **柔軟性**: 実行時にAdapteeの種類や数を柔軟に変更できる（柔軟性◎）
- **言語制約なし**: 継承を使わないので、多重継承不可の言語でも容易に使える
- **複数対応**: 複数のAdapteeにも対応可能

**メリット**:

- 多重継承不要（単一継承言語でも使用可能）
- 柔軟性が高い（動的に切り替え可能）
- 複数のAdapteeに対応できる
- 拡張性が高い

**デメリット**:

- 実装がやや複雑（委譲の記述が必要）
- Adapteeのメソッドを直接オーバーライドできない
- 若干のパフォーマンスオーバーヘッド（委譲による）

**実装例（Java風の疑似コード）**:

```java
// Target（期待されるインターフェース）
interface Print {
    void printWeak();
    void printStrong();
}

// Adaptee（既存クラス）
class Banner {
    void showWithParen() {
        System.out.println("(Banner)");
    }
    void showWithAster() {
        System.out.println("*Banner*");
    }
}

// Adapter（委譲型）
class PrintBanner implements Print {
    private Banner banner;  // Adapteeを保持
    
    public PrintBanner(String string) {
        this.banner = new Banner(string);
    }
    
    public void printWeak() {
        banner.showWithParen();  // 委譲
    }
    public void printStrong() {
        banner.showWithAster();  // 委譲
    }
}
```

**出典**:

- Qiita: Adapterパターン - https://qiita.com/katsuya_tanaka/items/aacc219bf797400b638b
- note: デザインパターン学習ログ（Adapter パターン） - https://note.com/ryo_2025/n/ncf5d388a8ba9
- clear.rice.edu: Adapter Design Pattern - https://www.clear.rice.edu/comp310/JavaResources/patterns/adapter.html

**信頼度**: 高

---

### 3.3 各言語での実装例

#### 3.3.1 Perl実装例

**クラスアダプター（継承型）**:

```perl
package OldClass;

sub old_method {
    print "Old method called\n";
}

package Adapter;
our @ISA = qw(OldClass);  # 継承

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub new_method {
    my $self = shift;
    $self->old_method();  # 継承したメソッドを呼び出し
}

# 使用例
package main;
my $adapter = Adapter->new();
$adapter->new_method();  # "Old method called"
```

**オブジェクトアダプター（委譲型）**:

```perl
package OldClass;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub old_method {
    print "Old method called\n";
}

package Adapter;

sub new {
    my ($class, $adaptee) = @_;
    return bless { adaptee => $adaptee }, $class;
}

sub new_method {
    my $self = shift;
    $self->{adaptee}->old_method();  # 委譲
}

# 使用例
package main;
my $old_obj = OldClass->new();
my $adapter = Adapter->new($old_obj);
$adapter->new_method();  # "Old method called"
```

**Perl専用モジュール**:

```perl
# Class::Adapterを使用した実装例
use Class::Adapter;

package MyAdapter;
use base 'Class::Adapter';

sub new {
    my $class = shift;
    my $object = MyLegacyClass->new(@_);
    return $class->SUPER::new($object);
}

# 必要に応じてメソッドをオーバーライド
sub adapted_method {
    my $self = shift;
    return $self->_OBJECT_->legacy_method(@_);
}
```

**特徴**:

- Perlは多重継承をサポートしているため、クラスアダプターも実装可能
- `Class::Adapter` CPANモジュールを使うと、より柔軟なAdapter実装が可能
- 委譲型（オブジェクトアダプター）が推奨される（柔軟性・保守性の観点から）

**出典**:

- Ubuntu Manpage: Class::Adapter - https://manpages.ubuntu.com/manpages/trusty/en/man3/Class::Adapter.3pm.html
- 独自調査（Perl実装パターンの分析）

**信頼度**: 高

---

#### 3.3.2 他の言語での実装例

**Python（委譲型）**:

```python
# Adaptee（既存クラス）
class LegacyPaymentSystem:
    def make_old_payment(self, amount, currency):
        print(f"レガシーシステムで決済: {amount} {currency}")
        return f"OLD_TX_{amount}"

# Target（期待されるインターフェース）
class PaymentProcessor:
    def process(self, amount: float, currency: str) -> str:
        pass

# Adapter（委譲型）
class LegacyPaymentAdapter(PaymentProcessor):
    def __init__(self, legacy_system: LegacyPaymentSystem):
        self.legacy_system = legacy_system
    
    def process(self, amount: float, currency: str) -> str:
        return self.legacy_system.make_old_payment(amount, currency)

# 使用例
legacy = LegacyPaymentSystem()
adapter = LegacyPaymentAdapter(legacy)
adapter.process(1000, "JPY")  # "レガシーシステムで決済: 1000 JPY"
```

**JavaScript/TypeScript（委譲型）**:

```typescript
// Adaptee（既存クラス）
class OldLogger {
    logOldFormat(message: string): void {
        console.log(`[OLD] ${message}`);
    }
}

// Target（期待されるインターフェース）
interface Logger {
    log(message: string, level: string): void;
}

// Adapter（委譲型）
class LoggerAdapter implements Logger {
    private oldLogger: OldLogger;
    
    constructor(oldLogger: OldLogger) {
        this.oldLogger = oldLogger;
    }
    
    log(message: string, level: string = 'INFO'): void {
        this.oldLogger.logOldFormat(`[${level}] ${message}`);
    }
}

// 使用例
const oldLogger = new OldLogger();
const adapter = new LoggerAdapter(oldLogger);
adapter.log('Hello', 'INFO');  // "[OLD] [INFO] Hello"
```

**出典**:

- Qiita: 【実践】Adapterパターンで実現するレガシーシステムとの共存戦略 - https://qiita.com/Tadataka_Takahashi/items/39b22d4e5e0e35eb52d2
- Zenn: Pythonでデザインパターンを学ぼう (Adapter) - https://zenn.dev/shimakaze_soft/articles/21428033c4f4b9

**信頼度**: 高

---

## 4. 利点と欠点

### 4.1 メリット

**要点**:

Adapterパターンのメリットは以下の通りです：

**1. 再利用性の向上**

- 既存のクラスやライブラリのコードを変更せずに新しいインターフェースとして利用できる
- システムやサービスの再利用を促進する
- レガシーコードの有効活用が可能

**2. 拡張性の向上**

- 新しいクラスや他のシステムとの統合も、アダプターを追加するだけで簡単に拡張できる
- システムの成長に対応しやすい
- プラグイン的な拡張が可能

**3. 互換性の向上**

- 互換性のないインターフェース同士を橋渡しすることで、多様なシステムやサードパーティ製API、レガシーコードをシームレスに連携可能にする
- 異なるバージョンのAPIの共存が可能

**4. 分離性・保守性の向上**

- アダプターに変換処理を委譲することで、ビジネスロジックの本体には手を加えず、変換処理だけ分離して管理・保守がしやすくなる
- 単一責任原則（SRP: Single Responsibility Principle）の遵守
- テストが容易（アダプター単体でテスト可能）

**5. 段階的な移行が可能**

- レガシーシステムから新システムへの段階的な移行を支援
- リスクを最小化しながら、システムをモダナイズできる

**根拠**:

- GoF書籍における「既存のクラスを新しいインターフェースで再利用する」という明確な目的
- 実務でのレガシーシステム統合やAPI統合での成功事例

**出典**:

- Hangout Laboratory: 構造パターン入門: Adapter（適応者）パターン完全ガイド - https://hanlabo.co.jp/memorandum/3598/
- cstechブログ: Adapterパターンとは - https://cs-techblog.com/technical/adapter-pattern/
- note: Adapter - https://note.com/shirotabistudy/n/ne790e51b6e98
- GeeksforGeeks: Adapter Design Pattern - https://www.geeksforgeeks.org/system-design/adapter-pattern/

**信頼度**: 高

---

### 4.2 デメリット

**要点**:

Adapterパターンのデメリットは以下の通りです：

**1. 複雑性の増加**

- 余分なクラスや層が増えるため、クラス図や連携が複雑になりがち
- 小規模・単純な部分に過度に使うと無駄に設計が煩雑になる
- コードの可読性が低下する可能性

**2. パフォーマンスへの影響**

- インターフェースの変換により処理コストやオーバーヘッドが一定発生する
- 高頻度・スピード必須の部分での乱用は要注意
- 委譲によるメソッド呼び出しのオーバーヘッド

**3. 複数アダプターの管理コスト**

- 多種多様なインターフェースを扱う場合、それぞれアダプターが必要となり、メンテナンスの手間が増加する
- アダプターの数が増えると、全体像の把握が困難になる

**4. デバッグの困難さ**

- 問題が発生した際、アダプター層が介在することで、問題の特定が難しくなる場合がある
- スタックトレースが深くなる

**根拠**:

- 実務での失敗事例が技術コミュニティで共有されている
- 「パターンを使うこと」が目的化してしまうケースが報告されている

**出典**:

- Hangout Laboratory: 構造パターン入門: Adapter（適応者）パターン完全ガイド - https://hanlabo.co.jp/memorandum/3598/
- Java プログラミングTIPS: Adapter パターン - https://programming-tips.jp/archives/a2/94/index.html
- note: Adapter - https://note.com/shirotabistudy/n/ne790e51b6e98
- GeeksforGeeks: Adapter Design Pattern - https://www.geeksforgeeks.org/system-design/adapter-pattern/

**信頼度**: 高

---

### 4.3 注意点

**要点**:

Adapterパターンを適用する際の注意点は以下の通りです：

**1. 不要なアダプター乱用は避ける**

- シンプルに済むところまでアダプターで層を増やすと、全体設計の視認性や可読性が落ち、管理が煩雑になる
- 「パターンを使うこと」が目的化しないように注意
- 小規模な不一致は、直接修正する方が良い場合もある

**2. 委譲を優先し、継承は慎重に**

- 委譲型（オブジェクトアダプター）の方が依存度が低く、柔軟性があるためおすすめ
- 継承型（クラスアダプター）は、多重継承の問題や柔軟性の欠如に注意
- 継承型は、単純なケースや言語が多重継承をサポートしている場合のみ検討

**3. アダプターの性能を意識する**

- パフォーマンスクリティカルな構成ではアダプターによる遅延やコストにも配慮が必要
- 高頻度で呼び出される箇所には、アダプターの導入を慎重に検討する

**4. インターフェース設計の見直し**

- アダプターが多数必要になる場合、そもそもインターフェース設計に問題がある可能性がある
- 設計の根本的な見直しを検討する

**5. ドキュメント化**

- アダプターの存在理由、変換ロジック、既存システムとの関係を明確にドキュメント化する
- 将来のメンテナンスのために、設計意図を残す

**出典**:

- Java プログラミングTIPS: Adapter パターン - https://programming-tips.jp/archives/a2/94/index.html
- GeeksforGeeks: Adapter Design Pattern - https://www.geeksforgeeks.org/system-design/adapter-pattern/
- ドクロモエ: 【デザインパターン】アダプター（Adapter）パターンの本質とは？ - https://dokuro.moe/design-pattern-adapter/

**信頼度**: 高

---

## 5. 実践的なサンプル

### 5.1 シンプルな例：電圧変換アダプター

**概要**:

日本の家電（100V）をアメリカ（120V）で使用する際の電圧変換アダプターを模擬した例です。

**実装（Python）**:

```python
# Adaptee（既存の日本の家電）
class JapaneseAppliance:
    def use_100v(self):
        return "100Vで動作中"

# Target（アメリカの電源規格）
class AmericanOutlet:
    def provide_120v(self):
        pass

# Adapter（電圧変換アダプター）
class VoltageAdapter(AmericanOutlet):
    def __init__(self, japanese_appliance: JapaneseAppliance):
        self.appliance = japanese_appliance
    
    def provide_120v(self):
        # 実際は電圧変換処理が入る（ここでは簡略化）
        result = self.appliance.use_100v()
        return f"{result} → 120Vに変換して供給"

# 使用例
appliance = JapaneseAppliance()
adapter = VoltageAdapter(appliance)
print(adapter.provide_120v())  # "100Vで動作中 → 120Vに変換して供給"
```

**ポイント**:

- シンプルで理解しやすい例
- 実世界のアダプターの概念と対応している
- 委譲型の基本的な構造を示している

**出典**:

- 独自作成（一般的な例示パターン）

**信頼度**: 高

---

### 5.2 より実践的な例：決済APIの統一

**概要**:

複数の決済プロバイダ（PayPay, Stripe, 楽天ペイ）を統一インターフェースで管理する例です。

**実装（Python）**:

```python
from abc import ABC, abstractmethod
from typing import Dict

# Target（統一決済インターフェース）
class PaymentProcessor(ABC):
    @abstractmethod
    def process_payment(self, amount: float, currency: str) -> Dict:
        pass

# Adaptee 1（PayPay API）
class PayPayAPI:
    def execute_paypay_transaction(self, yen_amount: int):
        print(f"PayPay決済: {yen_amount}円")
        return {"status": "success", "transaction_id": f"PP_{yen_amount}"}

# Adaptee 2（Stripe API）
class StripeAPI:
    def charge(self, amount_cents: int, currency_code: str):
        print(f"Stripe決済: {amount_cents/100} {currency_code}")
        return {"id": f"stripe_{amount_cents}", "status": "succeeded"}

# Adaptee 3（楽天ペイ API）
class RakutenPayAPI:
    def make_payment(self, payment_data: Dict):
        amount = payment_data["amount"]
        print(f"楽天ペイ決済: {amount}円")
        return {"result": "OK", "ref": f"RP_{amount}"}

# Adapter 1（PayPay用）
class PayPayAdapter(PaymentProcessor):
    def __init__(self, paypay_api: PayPayAPI):
        self.api = paypay_api
    
    def process_payment(self, amount: float, currency: str) -> Dict:
        if currency != "JPY":
            raise ValueError("PayPayは円のみ対応")
        result = self.api.execute_paypay_transaction(int(amount))
        return {
            "success": result["status"] == "success",
            "transaction_id": result["transaction_id"],
            "provider": "PayPay"
        }

# Adapter 2（Stripe用）
class StripeAdapter(PaymentProcessor):
    def __init__(self, stripe_api: StripeAPI):
        self.api = stripe_api
    
    def process_payment(self, amount: float, currency: str) -> Dict:
        amount_cents = int(amount * 100)
        result = self.api.charge(amount_cents, currency)
        return {
            "success": result["status"] == "succeeded",
            "transaction_id": result["id"],
            "provider": "Stripe"
        }

# Adapter 3（楽天ペイ用）
class RakutenPayAdapter(PaymentProcessor):
    def __init__(self, rakuten_api: RakutenPayAPI):
        self.api = rakuten_api
    
    def process_payment(self, amount: float, currency: str) -> Dict:
        if currency != "JPY":
            raise ValueError("楽天ペイは円のみ対応")
        payment_data = {"amount": int(amount), "currency": "JPY"}
        result = self.api.make_payment(payment_data)
        return {
            "success": result["result"] == "OK",
            "transaction_id": result["ref"],
            "provider": "RakutenPay"
        }

# 使用例
def process_order(processor: PaymentProcessor, amount: float, currency: str):
    result = processor.process_payment(amount, currency)
    if result["success"]:
        print(f"✓ 決済成功 [{result['provider']}]: {result['transaction_id']}")
    else:
        print(f"✗ 決済失敗 [{result['provider']}]")

# 各決済システムの使用
paypay = PayPayAdapter(PayPayAPI())
stripe = StripeAdapter(StripeAPI())
rakuten = RakutenPayAdapter(RakutenPayAPI())

process_order(paypay, 1000, "JPY")   # PayPay決済
process_order(stripe, 50.00, "USD")  # Stripe決済
process_order(rakuten, 3000, "JPY")  # 楽天ペイ決済
```

**出力**:

```
PayPay決済: 1000円
✓ 決済成功 [PayPay]: PP_1000
Stripe決済: 50.0 USD
✓ 決済成功 [Stripe]: stripe_5000
楽天ペイ決済: 3000円
✓ 決済成功 [RakutenPay]: RP_3000
```

**ポイント**:

- 実務でよくあるユースケース（複数API統合）
- 統一インターフェースにより、クライアントコードは決済プロバイダーの詳細を知る必要がない
- 新しい決済プロバイダーの追加が容易（新しいAdapterを作るだけ）
- テストが容易（各Adapterを個別にテスト可能）

**出典**:

- Qiita: 【実践】Adapterパターンで実現するレガシーシステムとの共存戦略 - https://qiita.com/Tadataka_Takahashi/items/39b22d4e5e0e35eb52d2
- GitHub: design-pattern - https://github.com/kazumasamatsumoto/design-pattern

**信頼度**: 高

---

### 5.3 Perl実装例：レガシーデータベースAPIのラッピング

**概要**:

古いデータベースライブラリのAPIを、現代的なインターフェースでラップする例です。

**実装（Perl）**:

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Adaptee（レガシーデータベースライブラリ）
package LegacyDB;

sub new {
    my ($class, $config) = @_;
    return bless { config => $config }, $class;
}

sub db_connect {
    my $self = shift;
    say "レガシーDB接続: " . $self->{config};
    return 1;
}

sub exec_query {
    my ($self, $sql) = @_;
    say "レガシーSQL実行: $sql";
    return ["row1", "row2", "row3"];
}

sub db_close {
    my $self = shift;
    say "レガシーDB切断";
}

# Target（現代的なデータベースインターフェース）
package DatabaseInterface;

sub connect { die "Not implemented" }
sub execute { die "Not implemented" }
sub disconnect { die "Not implemented" }

# Adapter（委譲型）
package LegacyDBAdapter;
use parent 'DatabaseInterface';

sub new {
    my ($class, $legacy_db) = @_;
    return bless { db => $legacy_db }, $class;
}

sub connect {
    my $self = shift;
    $self->{db}->db_connect();
    say "[Adapter] 接続完了";
}

sub execute {
    my ($self, $query) = @_;
    say "[Adapter] クエリ実行: $query";
    my $results = $self->{db}->exec_query($query);
    # 結果を現代的な形式に変換
    return { rows => $results, count => scalar @$results };
}

sub disconnect {
    my $self = shift;
    $self->{db}->db_close();
    say "[Adapter] 切断完了";
}

# 使用例
package main;

sub process_database {
    my $db = shift;
    $db->connect();
    my $result = $db->execute("SELECT * FROM users");
    say "取得件数: " . $result->{count};
    $db->disconnect();
}

# レガシーDBをアダプター経由で使用
my $legacy = LegacyDB->new("legacy_config.conf");
my $adapter = LegacyDBAdapter->new($legacy);

process_database($adapter);
```

**出力**:

```
レガシーDB接続: legacy_config.conf
[Adapter] 接続完了
[Adapter] クエリ実行: SELECT * FROM users
レガシーSQL実行: SELECT * FROM users
取得件数: 3
レガシーDB切断
[Adapter] 切断完了
```

**ポイント**:

- Perlでの実践的なAdapter実装例
- 委譲を使ったオブジェクトアダプターパターン
- レガシーシステムを変更せずに、現代的なインターフェースで利用
- 結果の変換処理も含めた完全な例

**出典**:

- 独自作成（Perl実装パターンの実践例）

**信頼度**: 高

---

## 6. 内部リンク候補

本サイト内の関連記事：

- [デザインパターン概要](/warehouse/design-patterns-overview/) - デザインパターン全体の概要
- [デザインパターン調査ドキュメント](/warehouse/design-patterns-research/) - GoFパターンの包括的調査
- [第12回-これがデザインパターンだ！](/2025/12/30/164012/) - Strategyパターンの実例
- [第1回-Mooで覚えるオブジェクト指向プログラミング](/2021/10/31/191008/) - Perlでのオブジェクト指向基礎

---

## 7. 重要なリソースのリスト

### 7.1 公式書籍・定番書籍

| 書籍名 | 著者 | ISBN/ASIN | 備考 |
|-------|------|-----------|------|
| **Design Patterns: Elements of Reusable Object-Oriented Software** | Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides | ISBN: 978-0201633610 | GoF原典、Adapterパターンの定義元 |
| **Head First Design Patterns (2nd Edition)** | Eric Freeman, Elisabeth Robson | ISBN: 978-1492078005 | 初心者向け、視覚的でわかりやすい |
| **Dive Into Design Patterns** | Alexander Shvets | - | Refactoring Guru著者、多言語対応 |

### 7.2 信頼性の高いWebリソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **Refactoring Guru - Adapter** | https://refactoring.guru/ja/design-patterns/adapter | 視覚的な解説、多言語コード例 |
| **GeeksforGeeks - Adapter Pattern** | https://www.geeksforgeeks.org/system-design/adapter-pattern/ | 網羅的、実装例豊富 |
| **Qiita - Adapter/Wrapperパターン** | https://qiita.com/OtsukaTomoaki/items/21f083125f936c6f464b | 日本語、詳細な解説 |
| **Baeldung - Adapter Pattern in Java** | https://www.baeldung.com/java-adapter-pattern | Java実装、実践的 |

### 7.3 CPAN（Perl）モジュール

| モジュール名 | URL | 説明 |
|------------|-----|------|
| **Class::Adapter** | https://metacpan.org/pod/Class::Adapter | Adapterパターンの汎用実装 |

---

## 8. 調査結果のサマリー

### 8.1 主要な発見

1. **Adapterパターンの本質**: インターフェースの不一致を解消し、既存資産を再利用するための構造パターン
2. **2つの実装方式**: クラスアダプター（継承型）とオブジェクトアダプター（委譲型）があり、柔軟性の観点から委譲型が推奨される
3. **実務での重要性**: レガシーシステムの統合、サードパーティAPIの統一、段階的なシステム移行に不可欠
4. **注意点**: 過度な適用は複雑性を増加させる。シンプルさとのバランスが重要

### 8.2 技術的な正確性を担保するための重要なリソース

- **GoF原典**: Adapterパターンの正式な定義と目的
- **Refactoring Guru**: 視覚的に理解しやすい解説とコード例
- **GeeksforGeeks**: 網羅的な説明と複数言語での実装例
- **実務事例（Qiita等）**: 実践的なユースケースと失敗事例

### 8.3 不明点・今後の調査が必要な領域

- Adapterパターンとマイクロサービスアーキテクチャの関係
- パフォーマンスの詳細な測定データ
- 大規模システムでのAdapter管理のベストプラクティス
- 関数型プログラミング言語でのAdapterパターンの適用

---

**調査完了**: 2025年12月31日

**調査者**: 調査・情報収集オタク専門家

**信頼度評価**: 高（公式書籍、著名な技術サイト、実務事例を総合的に調査）
