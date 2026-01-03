---
date: 2026-01-02T14:53:23+09:00
description: 振る舞いパターンInterpreterについての調査結果。概要、用途、サンプル、利点・欠点を整理
draft: false
epoch: 1767333203
image: /favicon.png
iso8601: 2026-01-02T14:53:23+09:00
tags:
  - design-patterns
  - gof
  - interpreter
  - behavioral-patterns
title: Interpreterパターン調査ドキュメント
---

# Interpreterパターン調査ドキュメント

## 調査目的

GoF（Gang of Four）デザインパターンの振る舞いパターンに分類されるInterpreterパターンについて調査を行い、概要、用途、サンプル、利点・欠点を整理する。

- **調査対象**: Interpreterパターン（振る舞いパターン）
- **想定読者**: デザインパターンを学習中のソフトウェアエンジニア
- **調査実施日**: 2025年12月31日

---

## 1. Interpreterパターンの概要

### 1.1 定義

**要点**:

- Interpreterパターンは、言語の文法を表現するクラス階層を定義し、その文法に従って文（文章・式）を解釈するインタプリタを提供するパターンである
- 各クラスが文法規則を1つずつカプセル化し、これらを組み合わせて複雑な式を解釈・処理できる
- 特定のコードではなく、文法規則をオブジェクト構造（抽象構文木）として表現する設計アイデアである

**根拠**:

- GoF書籍「Design Patterns: Elements of Reusable Object-Oriented Software」において、振る舞いパターンの1つとして定義されている
- 「言語の文法表現を定義し、その文法に従って文を解釈するインタプリタを提供する」と記載

**出典**:

- GeeksforGeeks: Interpreter Design Pattern - https://www.geeksforgeeks.org/system-design/interpreter-design-pattern/
- Spring Framework Guru: Interpreter Pattern - https://springframework.guru/gang-of-four-design-patterns/interpreter-pattern/
- Visual Paradigm Tutorials: Interpreter Pattern Tutorial - https://tutorials.visual-paradigm.com/interpreter-pattern-tutorial/

**信頼度**: 高

---

### 1.2 パターンの構造

**構成要素（参加者）**:

Interpreterパターンは以下の5つの主要なコンポーネントで構成される。

| コンポーネント | 役割 | 例 |
|---------------|------|-----|
| **AbstractExpression** | すべての式に共通のinterpret(context)メソッドを宣言する抽象クラスまたはインターフェース | `Expression`インターフェース |
| **TerminalExpression** | 文法の終端記号（リーフノード）を実装。最も単純な要素を表現 | 数値、変数、リテラル |
| **NonterminalExpression** | 文法の非終端記号（複合ノード）を実装。他の式を組み合わせて解釈 | 演算子（+、-、AND、OR） |
| **Context** | インタプリタ全体で共有される情報を保持 | 変数テーブル、入力文字列 |
| **Client** | 抽象構文木（AST）を構築し、ルートノードのinterpretを呼び出す | メインプログラム |

**クラス構造図（概念）**:

```
Client ──────────────────────────────────────────────────────────────
    │
    ├── Context（共有情報）
    │
    └── AbstractExpression（抽象/インターフェース）
            │
            ├── TerminalExpression（終端：リーフ）
            │
            └── NonterminalExpression（非終端：複合）
                    │
                    └── 子Expression（再帰的に構成）
```

**出典**:

- GeeksforGeeks: Interpreter Design Pattern - https://www.geeksforgeeks.org/system-design/interpreter-design-pattern/
- Visual Paradigm Tutorials - https://tutorials.visual-paradigm.com/interpreter-pattern-tutorial/

**信頼度**: 高

---

## 2. 用途・適用場面

### 2.1 主な用途

**要点**:

Interpreterパターンは以下のような場面で適用される。

| 用途 | 説明 | 具体例 |
|------|------|--------|
| **数式評価器** | 数学的な式を解析・評価 | 電卓、スプレッドシートの数式、科学計算ツール |
| **ドメイン固有言語（DSL）** | アプリケーション固有のミニ言語を実装 | ビジネスルールエンジン、設定ファイル形式 |
| **クエリ言語** | SQL風の問い合わせを解釈 | Excel検索、簡易データベースクエリ |
| **正規表現エンジン** | パターンマッチングの構文を解釈 | 入力検証、テキスト検索 |
| **テンプレートエンジン** | 変数置換やループの構文を処理 | HTML生成（Jinja2、Liquid等） |
| **設定・スクリプト解析** | カスタム設定ファイルやスクリプトを処理 | Makefile、Infrastructure as Code |

**根拠**:

- 多くの技術文献で、上記の適用例が報告されている
- GoF書籍においても、正規表現エンジンが代表例として挙げられている

**出典**:

- Software Patterns Lexicon: Interpreter Pattern Use Cases - https://softwarepatternslexicon.com/java/behavioral-patterns/interpreter-pattern/use-cases-and-examples/
- ScholarHat: Interpreter Design Pattern - https://www.scholarhat.com/tutorial/designpatterns/interpreter-design-pattern
- Reactive Programming: Interpreter - https://reactiveprogramming.io/blog/en/design-patterns/interpreter

**信頼度**: 高

---

### 2.2 適用の判断基準

**使用すべき場面**:

- シンプルで安定した文法を持つ言語を解釈する必要がある場合
- 問題が「言語の文」として自然に表現できる場合
- 文法の拡張（新しい式の追加）が頻繁に発生する場合
- 既存コードを変更せずに新しい文法規則を追加したい場合

**使用を避けるべき場面**:

- 文法が複雑で、多くの規則を持つ場合（SQLやプログラミング言語など）
- パフォーマンスが重要な場合（再帰的な解釈はオーバーヘッドを生む）
- より適切なパーサージェネレーター（ANTLR、yacc等）が利用可能な場合

**出典**:

- Software Particles: Design Patterns – Interpreter - https://softwareparticles.com/design-patterns-interpreter/
- Software System Design: Interpreter Pattern - https://softwaresystemdesign.com/design-pattern/behavioral-patterns/interpreter/

**信頼度**: 高

---

## 3. サンプルコード

### 3.1 Javaによる論理式インタプリタの例

以下は、論理式（AND/OR）を解釈するインタプリタの実装例である。

**3.1.1 Expressionインターフェース（AbstractExpression）**

```java
// Java 11+
public interface Expression {
    boolean interpret(String context);
}
```

**3.1.2 TerminalExpression（終端式）**

```java
// Java 11+
public class TerminalExpression implements Expression {
    private String data;

    public TerminalExpression(String data) {
        this.data = data;
    }

    @Override
    public boolean interpret(String context) {
        return context.contains(data);
    }
}
```

**3.1.3 NonterminalExpression（非終端式：AND/OR）**

```java
// Java 11+
public class AndExpression implements Expression {
    private Expression expr1;
    private Expression expr2;

    public AndExpression(Expression expr1, Expression expr2) {
        this.expr1 = expr1;
        this.expr2 = expr2;
    }

    @Override
    public boolean interpret(String context) {
        return expr1.interpret(context) && expr2.interpret(context);
    }
}

public class OrExpression implements Expression {
    private Expression expr1;
    private Expression expr2;

    public OrExpression(Expression expr1, Expression expr2) {
        this.expr1 = expr1;
        this.expr2 = expr2;
    }

    @Override
    public boolean interpret(String context) {
        return expr1.interpret(context) || expr2.interpret(context);
    }
}
```

**3.1.4 Client（使用例）**

```java
// Java 11+
public class InterpreterDemo {
    public static void main(String[] args) {
        // 終端式を作成
        Expression isJava = new TerminalExpression("Java");
        Expression isPattern = new TerminalExpression("Pattern");

        // 非終端式を作成（Java AND Pattern）
        Expression isJavaPattern = new AndExpression(isJava, isPattern);

        // コンテキスト（入力文字列）
        String context = "Java Design Pattern";

        // 解釈を実行
        System.out.println("Context: " + context);
        System.out.println("Java AND Pattern? " + isJavaPattern.interpret(context));
        // 出力: Java AND Pattern? true

        // OR式の例
        Expression isPython = new TerminalExpression("Python");
        Expression isJavaOrPython = new OrExpression(isJava, isPython);
        System.out.println("Java OR Python? " + isJavaOrPython.interpret(context));
        // 出力: Java OR Python? true
    }
}
```

**出典**:

- GeeksforGeeks: Interpreter Design Pattern in Java - https://www.geeksforgeeks.org/java/interpreter-design-pattern-in-java/
- Baeldung: Interpreter Design Pattern in Java - https://www.baeldung.com/java-interpreter-pattern
- BigBoxCode: Design Pattern: Interpreter Pattern in Java - https://bigboxcode.com/design-pattern-interpreter-pattern-java

**信頼度**: 高

---

### 3.2 Pythonによる論理式インタプリタの例

```python
# Python 3.8+
from abc import ABC, abstractmethod

# AbstractExpression
class Expression(ABC):
    @abstractmethod
    def interpret(self, context: str) -> bool:
        pass

# TerminalExpression
class TerminalExpression(Expression):
    def __init__(self, data: str):
        self.data = data

    def interpret(self, context: str) -> bool:
        return self.data in context

# NonterminalExpression: AND
class AndExpression(Expression):
    def __init__(self, expr1: Expression, expr2: Expression):
        self.expr1 = expr1
        self.expr2 = expr2

    def interpret(self, context: str) -> bool:
        return self.expr1.interpret(context) and self.expr2.interpret(context)

# NonterminalExpression: OR
class OrExpression(Expression):
    def __init__(self, expr1: Expression, expr2: Expression):
        self.expr1 = expr1
        self.expr2 = expr2

    def interpret(self, context: str) -> bool:
        return self.expr1.interpret(context) or self.expr2.interpret(context)

# Client
if __name__ == "__main__":
    context = "Java Design Pattern"

    is_java = TerminalExpression("Java")
    is_pattern = TerminalExpression("Pattern")

    # Java AND Pattern
    is_java_pattern = AndExpression(is_java, is_pattern)
    print(f"Java AND Pattern? {is_java_pattern.interpret(context)}")  # True

    # Java OR Python
    is_python = TerminalExpression("Python")
    is_java_or_python = OrExpression(is_java, is_python)
    print(f"Java OR Python? {is_java_or_python.interpret(context)}")  # True
```

**出典**:

- GitHub: RefactoringGuru/design-patterns-python - https://github.com/RefactoringGuru/design-patterns-python

**信頼度**: 高

---

### 3.3 数式評価器の概念例

数式 `5 + 3 * 2` を評価する場合の構造：

```
        [Add]
       /    \
    [Num]   [Mul]
      5     /    \
        [Num]   [Num]
          3       2
```

この抽象構文木（AST）を再帰的にinterpretすることで、結果 `11` を得る。

---

## 4. 利点・欠点

### 4.1 利点

| 利点 | 説明 |
|------|------|
| **拡張性が高い** | 新しい文法規則を追加する際、新しいExpressionクラスを追加するだけで良い。既存コードの変更が不要 |
| **関心の分離** | 文法規則と解釈ロジックが明確に分離され、コードの理解・保守が容易 |
| **再利用性** | 文法規則をカプセル化したクラスは、異なるシステムや場面で再利用可能 |
| **シンプルな文法に最適** | 数式、検索クエリ、シンプルなスクリプト言語など、単純な文法の実装に適している |
| **DSL実装に有効** | ドメイン固有言語（DSL）、設定ファイル形式、ルールエンジンの実装に適している |
| **オブジェクト指向的** | 文法規則をクラス階層として表現するため、オブジェクト指向設計の原則に沿っている |

**出典**:

- ScholarHat: Interpreter Design Pattern - https://www.scholarhat.com/tutorial/designpatterns/interpreter-design-pattern
- DevelopersVoice: Interpreter Design Pattern in C# - https://developersvoice.com/blog/behavioral-design-patterns/design-pattern-interpreter/

**信頼度**: 高

---

### 4.2 欠点

| 欠点 | 説明 |
|------|------|
| **複雑な文法には不向き** | 文法が複雑になると、クラス数が爆発的に増加し、管理が困難になる |
| **パフォーマンスの問題** | 再帰的な解釈とオブジェクト生成により、パフォーマンスが低下する可能性がある |
| **クラスの増殖** | 各文法規則に対応するクラスが必要なため、多数の小さなクラスが生成される |
| **保守の難しさ** | 大規模な文法を持つ場合、クラス階層の保守が困難になる |
| **パーサーの責任がクライアントに** | 抽象構文木（AST）の構築はクライアント側の責任となり、複雑になりやすい |

**出典**:

- Wikipedia: Interpreter pattern - https://en.wikipedia.org/wiki/Interpreter_pattern
- W3Reference: The Benefits and Drawbacks of Using the Interpreter Pattern - https://www.w3reference.com/software-design-patterns/the-benefits-and-drawbacks-of-using-the-interpreter-pattern/
- Software System Design: Interpreter Pattern - https://softwaresystemdesign.com/design-pattern/behavioral-patterns/interpreter/

**信頼度**: 高

---

### 4.3 利点・欠点サマリー表

| 観点 | 利点 | 欠点 |
|------|------|------|
| 拡張性 | 新しい式を簡単に追加可能 | 複雑な文法ではクラス数が爆発 |
| パフォーマンス | — | 再帰的解釈によるオーバーヘッド |
| 保守性 | 関心の分離により理解しやすい | 大規模階層の管理が困難 |
| 適用範囲 | シンプルな文法・DSLに最適 | 本格的な言語には不適切 |

---

## 5. 他のパターンとの関係

### 5.1 関連パターン

| パターン | 関係 |
|---------|------|
| **Composite** | 抽象構文木（AST）はCompositeパターンの構造を持つ。NonterminalExpressionがComposite、TerminalExpressionがLeafに対応 |
| **Iterator** | 抽象構文木を走査する際にIteratorパターンを使用できる |
| **Visitor** | 式に対する操作（評価以外の処理）を追加する場合、Visitorパターンと組み合わせる |
| **Flyweight** | 終端記号が繰り返し出現する場合、Flyweightパターンでインスタンスを共有できる |

**出典**:

- Refactoring Guru: Design Patterns - https://refactoring.guru/design-patterns
- GeeksforGeeks: Interpreter Design Pattern - https://www.geeksforgeeks.org/system-design/interpreter-design-pattern/

**信頼度**: 高

---

## 6. 実世界での適用例

### 6.1 現実のプロダクトでの使用例

| プロダクト/技術 | 適用場面 |
|----------------|---------|
| **正規表現エンジン** | 正規表現構文の解釈とパターンマッチング |
| **SQL処理系** | SQLクエリの解析と実行（簡易的なもの） |
| **Spring Expression Language (SpEL)** | Spring Frameworkの式言語 |
| **ANTLR** | 文法定義からパーサーを生成（Interpreterパターンの発展形） |
| **計算機アプリケーション** | 数式の入力と評価 |
| **テンプレートエンジン** | Jinja2、Liquid、Twigなど |

**出典**:

- Baeldung: Interpreter Design Pattern in Java - https://www.baeldung.com/java-interpreter-pattern
- Java Design Patterns: Interpreter - https://java-design-patterns.com/patterns/interpreter/

**信頼度**: 高

---

## 7. 内部リンク調査

### 7.1 関連記事（デザインパターン・オブジェクト指向）

リポジトリ内のデザインパターン関連コンテンツ:

| ファイルパス | 内部リンク | 関連度 |
|-------------|-----------|--------|
| `/content/warehouse/design-patterns-overview.md` | （調査ドキュメント） | 高 |
| `/content/warehouse/design-patterns-research.md` | （調査ドキュメント） | 高 |
| `/content/post/2021/10/31/191008.md` | `/2021/10/31/191008/` | 中（Moo OOP） |

---

## 8. 参考文献・参考サイト

### 8.1 公式書籍・定番書籍

| 書籍名 | 著者 | 備考 |
|-------|------|------|
| **Design Patterns: Elements of Reusable Object-Oriented Software** | Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides | GoF原典、Interpreterパターンの定義元 |
| **Head First Design Patterns (2nd Edition)** | Eric Freeman, Elisabeth Robson | 初心者向け、視覚的解説 |
| **Dive Into Design Patterns** | Alexander Shvets | Refactoring Guru著者 |

### 8.2 信頼性の高いWebリソース

| リソース名 | URL | 特徴 |
|-----------|-----|------|
| **Refactoring Guru** | https://refactoring.guru/design-patterns/interpreter | 視覚的解説、多言語コード例 |
| **GeeksforGeeks** | https://www.geeksforgeeks.org/system-design/interpreter-design-pattern/ | 網羅的解説 |
| **Baeldung** | https://www.baeldung.com/java-interpreter-pattern | Java実装例 |
| **SourceMaking** | https://sourcemaking.com/design_patterns/interpreter | パターン詳細解説 |
| **Java Design Patterns** | https://java-design-patterns.com/patterns/interpreter/ | オープンソース実装例 |

### 8.3 GitHub上の実装例

| リポジトリ | 言語 | URL |
|-----------|------|-----|
| **iluwatar/java-design-patterns** | Java | https://github.com/iluwatar/java-design-patterns |
| **RefactoringGuru/design-patterns-python** | Python | https://github.com/RefactoringGuru/design-patterns-python |
| **faif/python-patterns** | Python | https://github.com/faif/python-patterns |

---

## 9. 調査結果のサマリー

### 9.1 主要な発見

1. **Interpreterパターンは言語解釈に特化**: 文法規則をクラス階層として表現し、抽象構文木（AST）を再帰的に解釈するパターンである
2. **シンプルな文法に最適**: 複雑な文法には不向きで、DSL、数式評価、簡易クエリ言語などに適用される
3. **拡張性と保守性のトレードオフ**: 新しい式の追加は容易だが、文法が複雑化するとクラス数が増大し保守が困難になる
4. **Compositeパターンとの密接な関係**: 抽象構文木の構造はCompositeパターンそのものである

### 9.2 適用判断のガイドライン

| 条件 | 推奨 |
|------|------|
| シンプルで安定した文法 | Interpreterパターンを適用 |
| 複雑で頻繁に変更される文法 | パーサージェネレーター（ANTLR等）を検討 |
| パフォーマンスが重要 | 他のアプローチを検討 |
| DSL・ルールエンジンの実装 | Interpreterパターンが有効 |

---

**調査完了**: 2025年12月31日
