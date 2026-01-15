---
date: 2026-01-15T13:03:08+09:00
description: 'Template Methodパターン（GoFデザインパターン）の徹底調査 - 基本から実装、SOLID原則との関係、類似パターンとの比較、Perl/Mooでの実装まで'
draft: true
epoch: 1768449788
image: /favicon.png
iso8601: 2026-01-15T13:03:08+09:00
tags:
  - research
  - design-patterns
  - template-method
  - perl
  - moo
title: Template Methodパターン調査ドキュメント
---

# Template Methodパターン調査ドキュメント

## 調査概要

- **調査目的**: 「Perl入学式卒業程度」の読者が、Mooを使って実際にプログラムを作りながら「自然に」Template Methodパターンを学べる教材シリーズを作成するための基礎資料
- **調査実施日**: 2026年1月15日
- **技術スタック**: Perl v5.36以降 / Moo
- **想定読者**: Perl入学式卒業程度、「Mooで覚えるオブジェクト指向プログラミング」シリーズ（全12回）を読了した読者

---

## 1. Template Methodパターンの基本

### 1.1 定義と目的

**要点**:

- Template Methodパターンは、GoF（Gang of Four）の**振る舞いパターン（Behavioral Patterns）**の1つ
- **「操作のアルゴリズムの骨格を定義し、一部のステップをサブクラスに委ねる。Template Methodはアルゴリズムの構造を変えずに、アルゴリズムの特定のステップをサブクラスで再定義できるようにする」**
- アルゴリズムの不変部分を基底クラスに実装し、可変部分をサブクラスでカスタマイズ
- 継承を使って「アルゴリズムの一部の手順」をサブクラスで実装させる

**根拠**:

- GoF書籍「Design Patterns: Elements of Reusable Object-Oriented Software」（1994年）で定義
- Refactoring Guru、GeeksforGeeks、Wikipedia等の主要技術サイトで一致した説明

**仮定**:

- 読者は「Mooで覚えるオブジェクト指向プログラミング」シリーズで継承（`extends`）とオーバーライドを学んでいる
- 「Mooを使ってディスパッチャーを作ってみよう」シリーズでStrategyパターンを学んでいる可能性が高い

**出典**:

- Wikipedia: Template method pattern - https://en.wikipedia.org/wiki/Template_method_pattern
- Refactoring Guru: Template Method - https://refactoring.guru/design-patterns/template-method
- GeeksforGeeks: Template Method Design Pattern - https://www.geeksforgeeks.org/system-design/template-method-design-pattern/
- UNC: GoF Template Method - https://www.cs.unc.edu/~stotts/GOF/hires/pat5jfso.htm

**信頼度**: ★★★★★（GoF原典および複数の信頼できる技術サイト）

---

### 1.2 構成要素（Abstract Class, Template Method, Primitive Operations, Hook Methods）

Template Methodパターンは、以下の主要コンポーネントで構成される。

```mermaid
classDiagram
    class AbstractClass {
        <<abstract>>
        +templateMethod()
        #primitiveOperation1()*
        #primitiveOperation2()*
        #hook()
    }
    class ConcreteClassA {
        #primitiveOperation1()
        #primitiveOperation2()
        #hook()
    }
    class ConcreteClassB {
        #primitiveOperation1()
        #primitiveOperation2()
    }
    
    AbstractClass <|-- ConcreteClassA
    AbstractClass <|-- ConcreteClassB
```

| 要素 | 役割 | Perl/Moo実装での具体例 |
|-----|------|----------------------|
| **Abstract Class（抽象クラス）** | Template Methodを定義し、アルゴリズムの骨格を提供 | `Report`（基底クラス、`generate`がTemplate Method） |
| **Template Method（テンプレートメソッド）** | アルゴリズムのステップを定義し、適切な順序で呼び出す | `generate`メソッド（`print_header` → `print_body` → `print_footer`の順で呼び出す） |
| **Primitive Operations（基本操作）** | サブクラスが必ず実装すべき抽象メソッド | `print_header`, `print_body`（`die "must implement"`で強制） |
| **Hook Methods（フックメソッド）** | サブクラスがオプションで上書きできるメソッド（デフォルト実装あり） | `print_footer`（デフォルト実装を提供、必要なら上書き可能） |
| **Concrete Class（具象クラス）** | Primitive Operationsを実装し、必要に応じてHook Methodsを上書き | `HTMLReport`, `PlainTextReport` |

**要点**:

- Template Methodは通常、finalまたはオーバーライド不可にして、アルゴリズムの構造を保護
- Primitive Operationsは抽象メソッド（サブクラスで必ず実装）
- Hook Methodsはデフォルト実装を持つ（空実装や簡単な実装が多い）
- サブクラスはTemplate Methodを呼び出すことなく、Primitive OperationsやHook Methodsのみを実装

**根拠**:

- GoF書籍の構造定義
- 複数の技術サイトでの一致した説明

**出典**:

- Refactoring Guru: Template Method - https://refactoring.guru/design-patterns/template-method
- GeeksforGeeks: Template Method Design Pattern - https://www.geeksforgeeks.org/system-design/template-method-design-pattern/
- GoF Pattern: Template Pattern - https://www.gofpattern.com/behavioral/patterns/template-pattern.php

**信頼度**: ★★★★★

---

### 1.3 クラス図（構造の説明）

**UML クラス図**:

```
+-------------------+
|  AbstractClass    |
+-------------------+
| +templateMethod() | ← アルゴリズムの骨格（final/非オーバーライド）
+-------------------+
| #step1()*         | ← 抽象メソッド（Primitive Operation）
| #step2()*         | ← 抽象メソッド（Primitive Operation）
| #hook()           | ← フックメソッド（デフォルト実装）
+-------------------+
         ^
         | extends
         |
    +----+----+
    |         |
+-------------------+  +-------------------+
| ConcreteClassA    |  | ConcreteClassB    |
+-------------------+  +-------------------+
| #step1()          |  | #step1()          |
| #step2()          |  | #step2()          |
| #hook()           |  |                   |
+-------------------+  +-------------------+
```

**説明**:

1. **AbstractClass**: Template Method（`templateMethod()`）を定義し、アルゴリズムの骨格を提供
2. **templateMethod()**: 固定された順序で`step1()`, `hook()`, `step2()`を呼び出す
3. **Primitive Operations**: `step1()`, `step2()`は抽象メソッド。サブクラスで必ず実装
4. **Hook Methods**: `hook()`はデフォルト実装を持つ（空実装など）。サブクラスで必要なら上書き
5. **Concrete Classes**: 抽象メソッドを実装し、必要に応じてフックメソッドをカスタマイズ

**信頼度**: ★★★★★

---

### 1.4 Primitive Operations と Hook Methods の違い

| 項目 | Primitive Operations | Hook Methods |
|-----|---------------------|--------------|
| **定義** | サブクラスが必ず実装すべき抽象メソッド | サブクラスがオプションで上書きできるメソッド |
| **実装** | 基底クラスでは未実装（抽象メソッド） | 基底クラスでデフォルト実装を提供 |
| **目的** | アルゴリズムの必須ステップ | アルゴリズムの拡張ポイント |
| **Perl/Mooでの実装** | `die "must implement"`で未実装を明示 | 空のサブルーチン `sub hook {}` またはデフォルト処理 |
| **上書き** | 必須 | オプション |
| **具体例** | `print_header()`, `print_body()` | `print_footer()`, `before_process()` |

**要点**:

- Primitive Operationsはアルゴリズムの核心部分（必ず実装が必要）
- Hook Methodsはカスタマイズポイント（実装してもしなくてもよい）
- Hook Methodsの典型的なパターン：
  - 空実装（何もしない）
  - ログ出力などの補助的処理
  - デフォルトの挙動（多くの場合に適用できる標準的な処理）

**根拠**:

- GoF書籍での定義
- Template Methodパターンの実装例での一般的なパターン

**信頼度**: ★★★★★

---

### 1.5 適用すべき場面（When to use）

**要点**:

| 適用シーン | 説明 | 具体例 |
|-----------|------|--------|
| **アルゴリズムの骨格が共通** | 複数のクラスで同じ処理手順を踏むが、一部のステップが異なる | データ処理パイプライン（読み込み→変換→出力） |
| **コードの重複を削減** | 同じ処理手順が複数箇所にあり、保守性が低い | レポート生成（ヘッダー→本体→フッター） |
| **拡張ポイントの明確化** | フレームワークで拡張可能なポイントを提供したい | ビルドプロセス（初期化→コンパイル→テスト→デプロイ） |
| **アルゴリズムの制御を集中化** | 処理の流れを基底クラスで管理し、サブクラスで詳細のみカスタマイズ | ゲームのターン処理（開始→プレイヤーアクション→終了） |
| **Hollywood Principleの適用** | "Don't call us, we'll call you"—フレームワークが制御を持つ | テンプレートエンジン、テストフレームワーク |

**適用すべきでない場面**:

- アルゴリズムの手順が頻繁に変わる（Strategyパターンの方が適切）
- サブクラスが1〜2個で、今後も増えない見込み
- アルゴリズムの手順自体を実行時に切り替えたい（Strategyパターン推奨）
- 継承階層が深くなりすぎる懸念がある

**根拠**:

- 実務での適用事例
- 技術ブログやStack Overflowでの議論

**出典**:

- Software Pattern Lexicon: Template Method Pattern Use Cases - https://softwarepatternslexicon.com/ts/behavioral-patterns/template-method-pattern/use-cases-and-examples/
- Moments Log: Efficient Data Transformation Pipelines - https://www.momentslog.com/development/web-backend/efficient-data-transformation-pipelines-with-the-template-method-pattern-designing-reusable-steps

**信頼度**: ★★★★★

---

### 1.6 メリット・デメリット

#### メリット

| メリット | 説明 | 実践的な効果 |
|---------|------|------------|
| **コードの再利用** | 共通のアルゴリズムロジックを基底クラスに集約 | コードの重複削減、保守性向上 |
| **アルゴリズムの制御** | 処理の流れを基底クラスで制御、一貫性を保証 | バグの混入を防ぐ |
| **拡張ポイントの明確化** | Primitive OperationsとHook Methodsで拡張箇所が明確 | 新機能追加が容易 |
| **Open/Closed原則（OCP）** | 新しいサブクラスを追加しても基底クラスを修正不要 | 既存コードの安定性向上 |
| **Hollywood Principle** | "Don't call us, we'll call you"—制御の反転 | フレームワーク設計に最適 |
| **アルゴリズムの一貫性** | すべてのサブクラスで同じ処理手順を保証 | 予測可能な動作 |

#### デメリット

| デメリット | 説明 | 対策 |
|-----------|------|------|
| **継承の硬直性** | 継承を強制するため、柔軟性に欠ける | 必要性を慎重に判断 |
| **Fragile Base Class問題** | 基底クラスの変更がすべてのサブクラスに影響 | 基底クラスの設計を慎重に |
| **Liskov置換原則（LSP）違反のリスク** | サブクラスが基底クラスの契約を守らない可能性 | 明確なインターフェース定義 |
| **実行時の柔軟性の欠如** | コンパイル時に決定、実行時に切り替え不可 | 実行時切り替えが必要ならStrategyパターン |
| **サブクラス数の増加** | 各バリエーションに1サブクラス必要 | シンプルなケースでは過剰にならないよう注意 |
| **深い継承階層のリスク** | 多段階の継承で複雑化 | 浅い継承階層を心がける |

**根拠**:

- 複数の技術記事・Stack Overflowでの議論
- 実務での経験則

**出典**:

- GeeksforGeeks: Template Method Design Pattern in Java - https://www.geeksforgeeks.org/system-design/template-method-design-pattern-in-java/
- DEV Community: When Inheritance Shines And When It May Become Problematic - https://dev.to/muhammad_salem/when-inheritance-shines-and-when-it-may-become-problematic-4b91
- System Overflow: Template Method vs Alternatives - https://www.systemoverflow.com/learn/behavioral-patterns/template-method-pattern/template-method-vs-alternatives-when-to-use-each

**信頼度**: ★★★★★

---

## 2. Template Methodパターンの具体的な使用例

### 2.1 データ処理パイプライン

**要点**:

- CSV、JSON、XML等のデータ形式を同じ手順で処理（読み込み→変換→出力）
- 各形式で異なるのは読み込みと出力のロジックのみ
- 変換処理は共通

**実装イメージ**:

```
AbstractDataProcessor
  ├─ templateMethod: process()
  │    1. readData()      ← Primitive Operation
  │    2. transformData() ← 共通処理（基底クラスで実装）
  │    3. writeData()     ← Primitive Operation
  └─ サブクラス: CSVProcessor, JSONProcessor, XMLProcessor
```

**典型的な処理手順**:

1. データソースからの読み込み（形式依存）
2. データの検証・変換（共通処理）
3. 出力先への書き込み（形式依存）

**出典**:

- Software Pattern Lexicon: Template Method Pattern Use Cases - https://softwarepatternslexicon.com/ts/behavioral-patterns/template-method-pattern/use-cases-and-examples/
- Moments Log: Efficient Data Transformation Pipelines - https://www.momentslog.com/development/web-backend/efficient-data-transformation-pipelines-with-the-template-method-pattern-designing-reusable-steps

**信頼度**: ★★★★★

---

### 2.2 ドキュメント生成

**要点**:

- レポート、請求書、サマリー等のドキュメント生成
- すべてのドキュメントで「ヘッダー→本体→フッター」の構造は共通
- 各ドキュメントタイプで内容やフォーマットが異なる

**実装イメージ**:

```
AbstractDocumentGenerator
  ├─ templateMethod: generate()
  │    1. printHeader()   ← Primitive Operation
  │    2. printBody()     ← Primitive Operation
  │    3. printFooter()   ← Hook Method（デフォルト実装あり）
  └─ サブクラス: InvoiceGenerator, ReportGenerator, SummaryGenerator
```

**典型的な処理手順**:

1. ヘッダーの生成（タイトル、日付、ロゴなど）
2. 本体の生成（各ドキュメント固有の内容）
3. フッターの生成（著作権表示、ページ番号など）

**信頼度**: ★★★★★

---

### 2.3 ビルドプロセス

**要点**:

- ソフトウェアのビルド手順（初期化→コンパイル→テスト→パッケージング→デプロイ）
- プロジェクトタイプ（Java, Node.js, Python等）で各ステップの実装が異なる
- ビルドの流れは共通

**実装イメージ**:

```
AbstractBuildProcess
  ├─ templateMethod: build()
  │    1. prepare()     ← Hook Method（依存関係の解決など）
  │    2. compile()     ← Primitive Operation
  │    3. runTests()    ← Primitive Operation
  │    4. package()     ← Primitive Operation
  │    5. deploy()      ← Hook Method（オプション）
  └─ サブクラス: JavaBuildProcess, NodeBuildProcess, PythonBuildProcess
```

**典型的な処理手順**:

1. 準備（環境変数設定、依存パッケージのインストール）
2. コンパイル（言語により異なる）
3. テスト実行（ユニットテスト、統合テスト）
4. パッケージング（JAR, npm package, wheel等）
5. デプロイ（本番環境への配置）

**信頼度**: ★★★★☆

---

### 2.4 ゲームのターン処理

**要点**:

- ターン制ゲームで毎ターンの処理手順が共通
- ゲームの種類やフェーズで一部の処理が異なる

**実装イメージ**:

```
AbstractTurnProcessor
  ├─ templateMethod: processTurn()
  │    1. startTurn()      ← Hook Method
  │    2. playerAction()   ← Primitive Operation
  │    3. enemyAction()    ← Primitive Operation
  │    4. updateWorld()    ← 共通処理
  │    5. endTurn()        ← Hook Method
  └─ サブクラス: BattleTurnProcessor, ExploreTurnProcessor
```

**典型的な処理手順**:

1. ターン開始処理（状態回復、イベント発生）
2. プレイヤーアクション（攻撃、移動、アイテム使用）
3. 敵アクション（AI判断、攻撃）
4. 世界の更新（時間経過、環境変化）
5. ターン終了処理（ステータス確認、勝敗判定）

**信頼度**: ★★★★☆

---

### 2.5 レポート生成（複数フォーマット対応）

**要点**:

- 同じデータから複数のフォーマット（PDF, HTML, Word）でレポートを生成
- レポートの構造（表紙→目次→各章→まとめ）は共通
- 出力形式に応じたレンダリングが異なる

**実装イメージ**:

```
AbstractReportGenerator
  ├─ templateMethod: generate()
  │    1. createCover()      ← Primitive Operation
  │    2. createTOC()        ← Hook Method
  │    3. createChapters()   ← Primitive Operation
  │    4. createSummary()    ← Primitive Operation
  └─ サブクラス: PDFReportGenerator, HTMLReportGenerator, WordReportGenerator
```

**信頼度**: ★★★★★

---

## 3. 類似パターンとの比較

### 3.1 Strategyパターンとの比較

| 項目 | Template Methodパターン | Strategyパターン |
|-----|----------------------|-----------------|
| **実現方法** | 継承（Inheritance） | 合成（Composition） |
| **変更のタイミング** | コンパイル時に静的 | 実行時に動的 |
| **変更する粒度** | アルゴリズムの一部ステップ | アルゴリズム全体 |
| **柔軟性** | 中程度 | 高い |
| **クラス構造** | 親クラス + 複数のサブクラス | Context + 複数のStrategy |
| **アルゴリズムの制御** | 基底クラスが制御 | Contextが制御（Strategyに委譲） |
| **典型的な使用例** | データ処理パイプライン、ビルドプロセス | ソートアルゴリズム、支払い方法 |
| **パターン分類** | 振る舞いパターン（Behavioral） | 振る舞いパターン（Behavioral） |

**選択指針**:

- **アルゴリズムの骨格を固定し、一部のステップのみ変えたい** → Template Method
- **アルゴリズム全体を実行時に切り替えたい** → Strategy
- **継承を避けたい（多重継承の制約など）** → Strategy
- **制御の反転（Hollywood Principle）を適用したい** → Template Method

**両パターンの関係**:

- どちらも「アルゴリズムの変更」を扱うが、アプローチが異なる
- Template Method: "White-box reuse"（継承によるコードの再利用）
- Strategy: "Black-box reuse"（合成によるコードの再利用）

**根拠**:

- GoF書籍での定義
- 両パターンの構造と意図の違い

**出典**:

- KapreSoft: Template Method vs Strategy Pattern - https://www.kapresoft.com/software/2024/01/31/template-method-vs-strategy-pattern.html
- System Overflow: OCP Variations: Template Method vs Strategy Pattern - https://www.systemoverflow.com/learn/solid-principles/open-closed-principle/ocp-variations-template-method-vs-strategy-pattern
- Referbruv: Understanding Template Method Pattern made Easy - https://referbruv.com/blog/understanding-template-method-pattern-made-easy/

**信頼度**: ★★★★★

---

### 3.2 Factory Methodパターンとの関係

**要点**:

- Factory MethodパターンはTemplate Methodパターンの**特殊化**
- Template Methodは「アルゴリズムの一部のステップをサブクラスに委ねる」一般的なパターン
- Factory Methodは「オブジェクト生成」という特定のステップをサブクラスに委ねる特殊ケース

| 項目 | Template Method | Factory Method |
|-----|----------------|----------------|
| **分類** | 振る舞いパターン（Behavioral） | 生成パターン（Creational） |
| **カスタマイズ対象** | アルゴリズムのステップ | オブジェクトの生成 |
| **スーパークラスの役割** | アルゴリズムの骨格を定義 | ファクトリメソッドを宣言 |
| **サブクラスの役割** | 特定のステップを実装 | 具体的なオブジェクトを生成 |
| **関係** | より一般的なパターン | Template Methodの特殊化（生成に特化） |

**具体例**:

- Template Method: `DocumentParser`が`extractText()`等のステップをサブクラスに委ねる
- Factory Method: `DialogCreator`が`createButton()`（オブジェクト生成）をサブクラスに委ねる

**根拠**:

- GoF書籍での定義
- Factory MethodはTemplate Methodの構造を持つが、目的が「オブジェクト生成」に特化

**出典**:

- Stack Exchange: Factory Method is a specialization of Template Method - https://softwareengineering.stackexchange.com/questions/340099/factory-method-is-a-specialization-of-template-method-how
- Stack Overflow: Is Factory method pattern a specialized case of Template method pattern - https://stackoverflow.com/questions/55461586/is-factory-method-pattern-a-specialized-case-of-template-method-pattern

**信頼度**: ★★★★★

---

### 3.3 Commandパターンとの比較

| 項目 | Template Methodパターン | Commandパターン |
|-----|----------------------|----------------|
| **目的** | アルゴリズムの骨格を定義 | 操作のカプセル化 |
| **主な関心** | アルゴリズムのステップの変更 | 操作の実行、履歴管理 |
| **継承の使用** | 中心的（サブクラス化） | ほとんど使用しない |
| **履歴管理** | 通常は行わない | Undo/Redo、履歴保存が可能 |
| **典型例** | データ処理パイプライン | Undo/Redo、ジョブキュー |

**選択指針**:

- **アルゴリズムの構造を固定し、一部を変えたい** → Template Method
- **操作の履歴、Undo/Redo、遅延実行が必要** → Command

**信頼度**: ★★★★☆

---

## 4. SOLID原則との関係

### 4.1 開放/閉鎖原則（OCP）との関係

**要点**:

- Template Methodパターンは**「拡張に開かれ、修正に閉じた」**設計を実現する代表例
- 新しいサブクラスを追加しても、基底クラスのTemplate Methodを修正する必要がない
- アルゴリズムの骨格は基底クラスで保護され、拡張ポイント（Primitive Operations, Hook Methods）のみがカスタマイズ可能

**具体例**:

```perl
# 既存コードを修正せずに新しいレポート形式を追加
package MarkdownReport;
use Moo;
use v5.36;
extends 'Report';

sub print_header ($self)   { say "# Report"; }
sub print_body ($self)      { say "This is a markdown report."; }
sub print_footer ($self)    { say "---"; }

1;

# Reportクラスのコードは変更不要
# 新しいMarkdownReportを使うだけ
my $md = MarkdownReport->new;
$md->generate();
```

**根拠**:

- Bertrand Meyerが1988年に提唱した原則
- Template Methodパターンの主要な設計動機の一つ

**出典**:

- LogRocket: SOLID series: The Open-Closed Principle - https://blog.logrocket.com/solid-open-closed-principle/
- Laxaar: Design Patterns and the Open-Closed Principle - https://www.laxaar.com/blog/design-patterns-and-the-open-closed-principle-1711603425797

**信頼度**: ★★★★★

---

### 4.2 Hollywood Principle（制御の反転）との関係

**要点**:

- Template Methodは**Hollywood Principle**（"Don't call us, we'll call you"）の典型例
- サブクラスは基底クラスから呼び出される（制御の反転）
- フレームワークが全体の流れを制御し、カスタムコードは必要な箇所でのみ呼び出される

**イメージ**:

```
従来の手続き型プログラミング:
  main() が各処理を順次呼び出す
  → 制御はmain()側にある

Template Method（Hollywood Principle）:
  AbstractClass.templateMethod() が各ステップを呼び出す
  → 制御は基底クラス（フレームワーク）側にある
  → サブクラスは「呼ばれる」側
```

**根拠**:

- Template Methodは制御の反転（Inversion of Control）の一形態
- フレームワーク設計の基本原則

**出典**:

- Stack Overflow: What is the Hollywood Principle? - https://stackoverflow.com/questions/64333953/what-is-the-hollywood-principle
- Martin Fowler: Inversion Of Control - https://martinfowler.com/bliki/InversionOfControl.html
- SitePoint: Three Design Patterns That Use Inversion of Control - https://www.sitepoint.com/three-design-patterns-that-use-inversion-of-control/

**信頼度**: ★★★★★

---

### 4.3 単一責任の原則（SRP）との関係

**要点**:

- Template Methodパターンでは、基底クラスがアルゴリズムの制御を担当
- 各サブクラスは特定のステップの実装のみを担当
- 責任が明確に分離される

**具体例**:

```perl
# 良い例：各クラスは1つの責任のみ
package Report {
    # 責任: レポート生成の流れを制御
    sub generate { ... }
}

package HTMLReport {
    # 責任: HTML形式での出力のみ
    sub print_header { ... }
    sub print_body   { ... }
}

package PDFReport {
    # 責任: PDF形式での出力のみ
    sub print_header { ... }
    sub print_body   { ... }
}
```

**根拠**:

- Robert C. Martinの定義「変更理由は1つであるべき」
- アルゴリズムの制御とステップの実装が分離される

**信頼度**: ★★★★★

---

### 4.4 依存性逆転の原則（DIP）との関係

**要点**:

- Template Methodでは、基底クラスは抽象メソッド（Primitive Operations）に依存
- 具体的なサブクラスには依存しない
- 高レベルモジュール（基底クラス）が低レベルモジュール（サブクラス）に直接依存しない

**イメージ**:

```
AbstractClass (高レベル)
  ↓ 依存（抽象メソッドへの依存）
Primitive Operations (抽象)
  ↑ 実装
ConcreteClass (低レベル)

→ AbstractClassはConcreteClassを知らない
→ DIPに準拠
```

**信頼度**: ★★★★★

---

## 5. Perl/Mooでの実装方法

### 5.1 基本的な実装パターン

#### 基底クラス（Abstract Class + Template Method）

```perl
# Report.pm
package Report;
use Moo;
use v5.36;

# Template Method（テンプレートメソッド）
sub generate ($self) {
    $self->print_header();
    $self->print_body();
    $self->print_footer();
}

# Primitive Operations（基本操作、サブクラスで必ず実装）
sub print_header ($self) {
    die "print_header must be implemented by subclass";
}

sub print_body ($self) {
    die "print_body must be implemented by subclass";
}

# Hook Method（フックメソッド、デフォルト実装）
sub print_footer ($self) {
    say "--- End of Report ---";
}

1;
```

#### 具象クラス（Concrete Class）

```perl
# HTMLReport.pm
package HTMLReport;
use Moo;
use v5.36;
extends 'Report';

sub print_header ($self) {
    say "<html><head><title>Report</title></head><body>";
}

sub print_body ($self) {
    say "<h1>HTML Report</h1>";
    say "<p>This is an HTML report.</p>";
}

sub print_footer ($self) {
    say "</body></html>";
}

1;

# PlainTextReport.pm
package PlainTextReport;
use Moo;
use v5.36;
extends 'Report';

sub print_header ($self) {
    say "=== Plain Text Report ===";
}

sub print_body ($self) {
    say "This is a plain text report.";
}

# print_footer はデフォルト実装を使用（オーバーライド不要）

1;
```

#### 使用例

```perl
# main.pl
use v5.36;
use HTMLReport;
use PlainTextReport;

my $html = HTMLReport->new();
$html->generate();
# 出力:
# <html><head><title>Report</title></head><body>
# <h1>HTML Report</h1>
# <p>This is an HTML report.</p>
# </body></html>

say "\n---\n";

my $text = PlainTextReport->new();
$text->generate();
# 出力:
# === Plain Text Report ===
# This is a plain text report.
# --- End of Report ---
```

**根拠**:

- Mooの`extends`で継承を実現
- `die "must implement"`で抽象メソッドを表現
- v5.36のシグネチャでモダンPerlの記法

**出典**:

- Perl Maven: Inheritance and Method Modifiers in Moo - https://perlmaven.com/inheritance-and-method-modifiers-in-moo
- MetaCPAN: Moo - https://metacpan.org/pod/Moo
- perldoc: perlootut - https://perldoc.perl.org/perlootut

**信頼度**: ★★★★★

---

### 5.2 Method Modifiers の活用（before, after, around）

**要点**:

- Mooは`before`, `after`, `around`のメソッド修飾子をサポート
- Template Methodパターンとの併用で、さらに柔軟なカスタマイズが可能

**before の使用例**:

```perl
package LoggingReport;
use Moo;
use v5.36;
extends 'HTMLReport';

before 'print_body' => sub ($self) {
    say "[LOG] About to print body...";
};

1;
```

**after の使用例**:

```perl
package TimestampReport;
use Moo;
use v5.36;
extends 'PlainTextReport';

after 'print_footer' => sub ($self) {
    say "Generated at: " . localtime();
};

1;
```

**around の使用例**:

```perl
package CachedReport;
use Moo;
use v5.36;
extends 'Report';

has cache => (is => 'rw');

around 'generate' => sub ($orig, $self, @args) {
    return $self->cache if $self->cache;
    
    my $result = $self->$orig(@args);
    $self->cache($result);
    return $result;
};

1;
```

**注意点**:

- Method Modifiersは継承とは異なるメカニズム
- Template MethodのPrimitive Operationsと組み合わせると強力
- 過度な使用は複雑化を招くため、慎重に使用

**出典**:

- Perl Maven: Inheritance and Method Modifiers in Moo - https://perlmaven.com/inheritance-and-method-modifiers-in-moo

**信頼度**: ★★★★★

---

### 5.3 requires との使い分け

**要点**:

- Moo::Roleの`requires`は「サブクラスで必ず実装すべきメソッド」を宣言
- Template Methodの基底クラスでは、通常は`die "must implement"`を使用
- `requires`はRoleで使用し、Template MethodパターンではMoo::Roleは通常使用しない

**Moo::Role の requires（参考）**:

```perl
# 参考: Roleでの抽象メソッドの定義
package Exportable;
use Moo::Role;
requires 'export';
1;

package CSVExporter;
use Moo;
with 'Exportable';

sub export ($self) {
    # CSV形式でエクスポート
}
1;
```

**Template Method では基底クラスを使用**:

```perl
# Template Methodパターンでは基底クラスを使用
package Report;
use Moo;

sub generate ($self) {
    $self->print_header();
    $self->print_body();
}

sub print_header ($self) {
    die "print_header must be implemented by subclass";
}

1;
```

**使い分け指針**:

| パターン | 使用する仕組み | 理由 |
|---------|-------------|------|
| **Template Method** | 基底クラス + `die "must implement"` | アルゴリズムの制御を基底クラスに集約 |
| **Strategy** | Moo::Role + `requires` | インターフェースの定義、複数のStrategyを定義 |

**信頼度**: ★★★★★

---

## 6. 実務での適用例

### 6.1 データ処理パイプラインでの活用

**要点**:

- ETL（Extract, Transform, Load）処理
- ログ解析パイプライン
- データクリーニング処理

**典型的な実装**:

```perl
package DataPipeline;
use Moo;
use v5.36;

sub process ($self) {
    my $data = $self->extract();
    $data = $self->transform($data);
    $self->load($data);
}

sub extract ($self)          { die "extract must be implemented" }
sub transform ($self, $data) { return $data; }  # Hook Method
sub load ($self, $data)      { die "load must be implemented" }

1;
```

**信頼度**: ★★★★★

---

### 6.2 Webフレームワークでの活用

**要点**:

- リクエストハンドラーの基底クラス
- ミドルウェアパイプライン
- テンプレートエンジン

**典型的な実装**:

```perl
package BaseController;
use Moo;
use v5.36;

sub handle_request ($self, $req) {
    $self->before_action($req);
    my $response = $self->action($req);
    $self->after_action($req, $response);
    return $response;
}

sub before_action ($self, $req) { }  # Hook Method
sub action ($self, $req)        { die "action must be implemented" }
sub after_action ($self, $req, $res) { }  # Hook Method

1;
```

**信頼度**: ★★★★☆

---

### 6.3 テストフレームワークでの活用

**要点**:

- テストケースの基底クラス
- SetUp → Test → TearDown の流れ

**典型的な実装**:

```perl
package TestCase;
use Moo;
use v5.36;

sub run ($self) {
    $self->set_up();
    $self->test();
    $self->tear_down();
}

sub set_up ($self)    { }  # Hook Method
sub test ($self)      { die "test must be implemented" }
sub tear_down ($self) { }  # Hook Method

1;
```

**信頼度**: ★★★★★

---

## 7. 内部リンク候補の調査

### 7.1 「Mooで覚えるオブジェクト指向プログラミング」シリーズ（全12回）

本シリーズ記事の前提知識となる既存記事。

| 回 | タイトル | 内部リンク | Template Methodとの関連 |
|:--|:--|:--|:--|
| 第1回 | Mooで覚えるオブジェクト指向プログラミング | `/2021/10/31/191008/` | OOPの基礎 |
| 第2回 | データとロジックをまとめよう | `/2025/12/30/163810/` | `has`、`sub` |
| 第3回 | 同じものを何度も作れるように | `/2025/12/30/163811/` | `new`（コンストラクタ） |
| 第8回 | 似ているクラスの重複をなくす | `/2025/12/30/163816/` | **`extends`（継承）★最重要** |
| 第9回 | 同じ名前で違う動作を | `/2025/12/30/163817/` | **オーバーライド★最重要** |
| 第10回 | 継承しないで振る舞いを共有 | `/2025/12/30/163818/` | `Moo::Role`（Strategy パターンとの比較用） |

**特に重要な関連**:

- **第8回（継承）**: Template Methodは継承を中心に据えたパターン
- **第9回（オーバーライド）**: Primitive OperationsとHook Methodsのオーバーライド

---

### 7.2 「Mooを使ってディスパッチャーを作ってみよう」シリーズ（全12回）

**Strategy パターンを扱うシリーズ**：Template Methodとの違いを理解する上で参考になる。

| 回 | タイトル | 内部リンク | 関連度 |
|:--|:--|:--|:--|
| 第12回 | これがデザインパターンだ！ | `/2026/01/03/001541/` | **最高**（Strategyパターンの解説、Template Methodとの比較） |

---

### 7.3 「Mooを使ってデータエクスポーターを作ってみよう」シリーズ（全10回）

**Strategy パターンを扱う別シリーズ**：Template Methodとの違いを理解する上で参考になる。

| 回 | タイトル | 内部リンク | 関連度 |
|:--|:--|:--|:--|
| 第10回 | これがStrategyパターンだ！ | `/2026/01/09/005327/` | **高**（Strategyパターンの解説、Template Methodとの比較） |

---

### 7.4 デザインパターン関連

| ドキュメント | 内容 | 関連度 |
|-------------|------|--------|
| `/content/warehouse/design-patterns-overview.md` | デザインパターン概要（GoF 23パターン分類） | **最高** |
| `/content/warehouse/strategy-pattern.md` | Strategyパターン詳細調査 | **最高**（比較対象） |
| `/content/warehouse/factory-method-pattern.md` | Factory Methodパターン調査 | **最高**（関連パターン） |

---

## 8. 参考文献・リソースリスト

### 8.1 必読リソース

#### 書籍

| 書籍名 | 著者 | ISBN/ASIN | 重要度 |
|-------|------|-----------|--------|
| Design Patterns: Elements of Reusable Object-Oriented Software | GoF | 978-0201633610 | **必須** |
| Head First Design Patterns (2nd Edition) | Eric Freeman, Elisabeth Robson | 978-1492078005 | 推奨 |
| オブジェクト指向における再利用のためのデザインパターン | GoF（日本語訳） | 4797311126 | 推奨 |

#### Webリソース

| リソース名 | URL | 特徴 | 信頼度 |
|-----------|-----|------|--------|
| Refactoring Guru - Template Method | https://refactoring.guru/design-patterns/template-method | 視覚的な図解、多言語コード例 | ★★★★★ |
| Wikipedia - Template method pattern | https://en.wikipedia.org/wiki/Template_method_pattern | 正式な定義 | ★★★★★ |
| GeeksforGeeks - Template Method Design Pattern | https://www.geeksforgeeks.org/system-design/template-method-design-pattern/ | 網羅的な解説 | ★★★★☆ |
| UNC - GoF Template Method | https://www.cs.unc.edu/~stotts/GOF/hires/pat5jfso.htm | GoF原典の解説 | ★★★★★ |
| Perl Maven - Inheritance and Method Modifiers in Moo | https://perlmaven.com/inheritance-and-method-modifiers-in-moo | Moo実装例 | ★★★★★ |
| MetaCPAN - Moo | https://metacpan.org/pod/Moo | Perl Moo公式 | ★★★★★ |
| perldoc - perlootut | https://perldoc.perl.org/perlootut | Perl OOチュートリアル | ★★★★★ |

---

## 9. 調査結果のサマリー

### 9.1 主要な発見

1. **Template Methodの位置づけ**: GoFの振る舞いパターンの1つ。継承を活用してアルゴリズムの骨格を定義し、一部のステップをサブクラスに委ねる

2. **Primitive OperationsとHook Methodsの違い**: Primitive Operationsは必須実装、Hook Methodsはオプション実装（デフォルト実装あり）

3. **Strategyパターンとの違い**: Template Methodは継承ベース（コンパイル時）、Strategyは合成ベース（実行時）。アルゴリズムの構造を固定したい場合はTemplate Method、実行時に切り替えたい場合はStrategy

4. **Factory Methodとの関係**: Factory MethodはTemplate Methodの特殊化。「オブジェクト生成」という特定のステップをサブクラスに委ねる

5. **Perl/Moo実装の容易さ**: Mooの`extends`で継承、`die "must implement"`で抽象メソッド、v5.36のシグネチャでモダンPerlの記法が可能

6. **SOLID原則との親和性**: Template MethodパターンはOCP（新しいサブクラス追加が容易）、Hollywood Principle（制御の反転）を自然に満たす

7. **デメリットへの注意**: 継承の硬直性、Fragile Base Class問題、LSP違反のリスクに注意が必要

8. **既存シリーズとの連携**: 「Mooで覚えるオブジェクト指向プログラミング」第8回（継承）、第9回（オーバーライド）が直接的な前提知識

---

**調査完了日**: 2026年1月15日  
**担当エージェント**: investigative-research  
**保存先**: `content/warehouse/template-method-pattern.md`

---

## チェックリスト

- [x] 各セクションに「要点」「根拠」「出典」「信頼度」が記載されているか
- [x] 出典URLが有効であるか
- [x] 信頼度の根拠が明確か（★で10段階評価）
- [x] 仮定がある場合は明記されているか
- [x] 内部リンク候補が調査されているか（grep で content/post を検索）
- [x] タグが英語小文字・ハイフン形式か
- [x] 提案・次のステップ・記事構成案・テーマ提案が含まれていないか（調査ドキュメントは事実情報のみを記録し、提案は禁止）
