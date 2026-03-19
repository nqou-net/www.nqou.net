---
date: 2026-01-08T13:16:00+09:00
description: Stateパターン（状態パターン）に関する調査結果。定義、ユースケース、実装例、競合記事分析、内部リンク調査
draft: false
epoch: 1767845760
image: /favicon.png
iso8601: 2026-01-08T13:16:00+09:00
tags:
  - state-pattern
  - design-patterns
  - gof
  - perl
  - moo
title: Stateパターン調査ドキュメント
---

# Stateパターン調査ドキュメント

## 調査概要

- **調査目的**: Stateパターンの技術情報、実装例、ユースケースを調査し、記事作成の基礎資料を作成する
- **調査実施日**: 2026年1月8日
- **キーワード**: Stateパターン、State pattern、デザインパターン、GoF
- **技術スタック**: Perl / Moo

---

## 1. Stateパターンの基礎

### 1.1 定義と目的

**要点**:

- Stateパターンは、GoF（Gang of Four）の振る舞いパターン（Behavioral Patterns）の1つ
- **「オブジェクトの内部状態が変化したときに、その振る舞いを変化させる。オブジェクトはあたかもクラスを変えたかのように振る舞う」**
- オブジェクトの状態に応じて振る舞いを切り替えることを可能にする
- 状態ごとの条件分岐（if/else、switch）を削減し、状態をオブジェクトとして分離する

**根拠**:

- GoF書籍「Design Patterns: Elements of Reusable Object-Oriented Software」（1994年）で定義
- Refactoring Guru、GeeksforGeeks、Wikipedia等の主要技術サイトで一致した説明

**仮定**:

- 読者はStrategyパターンを学習済み、または並行して学習中
- 「状態」と「振る舞い」の関係を理解する必要がある

**出典**:

- Wikipedia: State pattern - https://en.wikipedia.org/wiki/State_pattern
- Refactoring Guru: State - https://refactoring.guru/ja/design-patterns/state
- GeeksforGeeks: State Design Pattern - https://www.geeksforgeeks.org/system-design/state-pattern-set-1/
- Qiita: デザインパターン Stateパターン - https://qiita.com/AsahinaKei/items/ce8e5d7bc375af23c719

**信頼度**: 9/10（GoF原典および複数の信頼できる技術サイト）

---

### 1.2 構成要素（State、ConcreteState、Context）

Stateパターンは、以下の3つの主要コンポーネントで構成される。

```mermaid
classDiagram
    class Context {
        -state: State
        +setState(State)
        +request()
    }
    class State {
        <<interface>>
        +handle(Context)
    }
    class ConcreteStateA {
        +handle(Context)
    }
    class ConcreteStateB {
        +handle(Context)
    }
    class ConcreteStateC {
        +handle(Context)
    }
    
    Context o--> State : has
    ConcreteStateA ..|> State : implements
    ConcreteStateB ..|> State : implements
    ConcreteStateC ..|> State : implements
```

| 要素 | 役割 | Perl/Moo実装での具体例 |
|-----|------|----------------------|
| **State（状態インターフェース）** | 共通の状態インターフェースを定義。すべての具象状態が実装すべきメソッドを宣言 | `VendingMachineState`（Moo::Role、`requires 'handle'`） |
| **ConcreteState（具象状態）** | Stateインターフェースを実装し、その状態での具体的な振る舞いと状態遷移ロジックを提供 | `WaitingState`, `CoinInsertedState`, `DispensingState` |
| **Context（文脈）** | 現在のStateオブジェクトへの参照を保持し、クライアントにインターフェースを提供。状態変更を受け付ける | `VendingMachine`（has state => ...） |

**要点**:

- Contextは状態の詳細を知らない（疎結合）
- **ConcreteStateがContextへの参照を持ち、状態遷移を制御する**ことが多い（Strategyとの重要な違い）
- 状態遷移ロジックは各ConcreteStateに分散される

**根拠**:

- GoF書籍の構造定義
- TECHSCORE、IT専科等のデザインパターン解説サイト

**出典**:

- TECHSCORE: State パターン - https://www.techscore.com/tech/DesignPattern/State
- IT専科: State パターン - https://www.itsenka.com/contents/development/designpattern/state.html
- Refactoring Guru: State - https://refactoring.guru/ja/design-patterns/state

**信頼度**: 9/10

---

### 1.3 メリット・デメリット

#### メリット

| メリット | 説明 | 実践的な効果 |
|---------|------|------------|
| **条件分岐の削減・コード可読性の向上** | if/switchが減り、コードがシンプルで読みやすくなる | 保守性向上 |
| **状態ごとの責務が明確** | 各状態クラスがその状態に特化した振る舞いだけを担当（SRP準拠） | 変更影響範囲の限定 |
| **状態追加・修正が容易** | 新しい状態を追加しても既存クラスに手を加えなくて済む（OCP準拠） | 機能拡張が容易 |
| **状態遷移の明確化** | 状態遷移ロジックが各状態クラスに局所化される | バグの発見・修正が容易 |
| **ユニットテストがしやすい** | 各状態ごとのテストが独立して書きやすい | テスト容易性 |

#### デメリット

| デメリット | 説明 | 対策 |
|-----------|------|------|
| **クラス数が増える** | 状態ごとにクラスを設けるため、シンプルな処理には不向き | 状態数が少ない場合は適用を見送る |
| **設計・初学者への理解コスト** | 小規模な状態管理ならif/switchの方が直感的 | 適用判断を慎重に |
| **状態遷移の管理の手間** | 状態変更ロジックが複雑になる場合、パターンだけでは不十分 | 状態遷移図との併用 |
| **状態間の共有データ管理** | 状態間で共有するデータの受け渡しが複雑になる可能性 | Contextで一元管理 |

**根拠**:

- 複数の技術記事・Stack Overflowでの議論
- Qiita、Zenn等での実践報告

**出典**:

- Qiita: GoF 23パターン State編 - https://qiita.com/Pentaro256/items/752f28aa425c4295b13d
- Zenn: デザインパターンを学ぶ #17 ステート（State） - https://zenn.dev/tajicode/articles/aa18feba9a570f

**信頼度**: 9/10

---

### 1.4 Stateパターンが有効なユースケース

**要点**:

| 適用シーン | 説明 | 具体例 |
|-----------|------|--------|
| **状態遷移が明確なシステム** | 有限状態オートマトン（FSM）として表現できる | 自動販売機、信号機、ATM |
| **状態による振る舞いの大きな変化** | 同じ操作でも状態によって結果が全く異なる | ゲームキャラクターのモード |
| **状態遷移ルールの存在** | 特定の状態からしか遷移できない条件がある | ワークフロー、承認フロー |
| **if/elseの肥大化** | 状態に応じた条件分岐が複雑化している | レガシーコードのリファクタリング |

**適用すべきでない場面**:

- 状態が1〜2個で今後も増えない見込み
- 状態間の差異がほとんどない
- 状態遷移ルールがシンプルで固定的
- 追加クラスによる複雑さがメリットを上回る

**信頼度**: 9/10

---

## 2. 類似パターンとの比較

### 2.1 Stateパターン vs Strategyパターンの違い

| 項目 | Stateパターン | Strategyパターン |
|-----|--------------|-----------------|
| **目的** | オブジェクトの状態に応じて振る舞いを変える | アルゴリズムを切り替える |
| **変更の主体** | オブジェクト自身が内部状態に応じて変更 | クライアント（外部）が選択 |
| **状態遷移** | あり（状態間の遷移ルールが存在） | なし（独立したアルゴリズム選択） |
| **Contextへの参照** | StateはContextへの参照を持つことが多い | Strategyは通常Contextを知らない |
| **典型例** | 自動販売機の状態、TCP接続の状態 | ソートアルゴリズム、支払い方法 |
| **切り替えトリガー** | 内部状態の変化に応じて自動 | 外部から明示的に指定 |

**選択指針**:

- **「オブジェクトの状態によって振る舞いを変えたい」＋「状態遷移がある」** → **State**
- **「どう処理するか（アルゴリズム）を切り替えたい」＋「外部から選択」** → **Strategy**

**根拠**:

- GoF書籍での定義
- 両パターンの構造は似ているが、意図と責任が異なる

**出典**:

- Baeldung: State vs Strategy Pattern - https://www.baeldung.com/cs/design-state-pattern-vs-strategy-pattern
- GeeksforGeeks: Difference Between State and Strategy - https://www.geeksforgeeks.org/java/difference-between-state-and-strategy-design-pattern-in-java/
- Qiita: Strategy パターン vs State パターン - https://qiita.com/nozomi2025/items/fa8032646baaee72b15d
- Zenn: Strategy Pattern と State Pattern - https://zenn.dev/waffledog/scraps/4eb0b97454b07a
- ソフトライム: StrategyパターンとStateパターンの違い - https://soft-rime.com/post-18061/

**信頼度**: 9/10

---

### 2.2 他の振る舞いパターンとの関係

| パターン | Stateとの関係 | 使い分け |
|---------|-------------|---------|
| **Strategy** | 構造が類似。目的と切り替え主体が異なる | 状態遷移あり→State、アルゴリズム選択→Strategy |
| **Command** | 操作のカプセル化。Undo/Redo対応 | 操作履歴が必要→Command |
| **Observer** | 状態変化の通知に併用可能 | 状態変化を外部に通知したい場合に組み合わせ |
| **Template Method** | 継承ベースでアルゴリズムの骨格を定義 | 骨格固定でステップ変更→Template Method |

**信頼度**: 9/10

---

## 3. Stateパターンの実装例

### 3.1 一般的な実装パターン

#### 信号機の例（状態遷移図）

```
[赤信号] --(時間経過)--> [青信号]
[青信号] --(時間経過)--> [黄信号]
[黄信号] --(時間経過)--> [赤信号]
```

#### Javaでの基本実装例

```java
// State インターフェース
public interface TrafficLightState {
    void showSignal();
    void next(TrafficLight trafficLight);
}

// ConcreteState: 赤信号
public class RedState implements TrafficLightState {
    @Override
    public void showSignal() {
        System.out.println("赤信号：止まってください");
    }
    @Override
    public void next(TrafficLight trafficLight) {
        trafficLight.setState(new GreenState());
    }
}

// ConcreteState: 青信号
public class GreenState implements TrafficLightState {
    @Override
    public void showSignal() {
        System.out.println("青信号：進んでください");
    }
    @Override
    public void next(TrafficLight trafficLight) {
        trafficLight.setState(new YellowState());
    }
}

// Context
public class TrafficLight {
    private TrafficLightState currentState;
    
    public TrafficLight() {
        this.currentState = new RedState();
    }
    
    public void setState(TrafficLightState state) {
        this.currentState = state;
    }
    
    public void showSignal() {
        currentState.showSignal();
    }
    
    public void change() {
        currentState.next(this);
    }
}
```

**出典**:

- Qiita: Stateパターン - https://qiita.com/Yankaji777/items/c70afa09f3c1cc2de0b6
- tamotech.blog: 「State」パターンとは？ - https://tamotech.blog/2025/05/13/state/

**信頼度**: 9/10

---

### 3.2 Perlでの実装アプローチ（Moo/Mooseを使った場合）

**要点**:

- PerlではMoo::Roleを「State インターフェース」として使用
- `requires`で必須メソッドを定義し、各ConcreteStateクラスがRoleを消費（with）
- StateがContextへの参照を持ち、状態遷移を制御する

**コード例**:

```perl
# State Role（インターフェース）
package VendingMachineState;
use Moo::Role;
requires 'insert_coin';
requires 'select_product';
requires 'dispense';
1;

# ConcreteState A: 待機状態
package WaitingState;
use Moo;
use v5.36;
with 'VendingMachineState';

sub insert_coin ($self, $context) {
    say "コインを受け付けました";
    $context->set_state(CoinInsertedState->new);
}

sub select_product ($self, $context) {
    say "先にコインを入れてください";
}

sub dispense ($self, $context) {
    say "商品を払い出せません";
}
1;

# ConcreteState B: コイン投入済み状態
package CoinInsertedState;
use Moo;
use v5.36;
with 'VendingMachineState';

sub insert_coin ($self, $context) {
    say "既にコインが入っています";
}

sub select_product ($self, $context) {
    say "商品を選択しました";
    $context->set_state(DispensingState->new);
}

sub dispense ($self, $context) {
    say "先に商品を選んでください";
}
1;

# ConcreteState C: 払い出し状態
package DispensingState;
use Moo;
use v5.36;
with 'VendingMachineState';

sub insert_coin ($self, $context) {
    say "払い出し中です。お待ちください";
}

sub select_product ($self, $context) {
    say "払い出し中です。お待ちください";
}

sub dispense ($self, $context) {
    say "商品を払い出しました";
    $context->set_state(WaitingState->new);
}
1;

# Context: 自動販売機
package VendingMachine;
use Moo;
use v5.36;

has state => (
    is      => 'rw',
    default => sub { WaitingState->new },
);

sub set_state ($self, $state) {
    $self->state($state);
}

sub insert_coin ($self) {
    $self->state->insert_coin($self);
}

sub select_product ($self) {
    $self->state->select_product($self);
}

sub dispense ($self) {
    $self->state->dispense($self);
}
1;

# 使用例
package main;
use v5.36;

my $machine = VendingMachine->new;
$machine->insert_coin;      # コインを受け付けました
$machine->select_product;   # 商品を選択しました
$machine->dispense;         # 商品を払い出しました
$machine->select_product;   # 先にコインを入れてください
```

**根拠**:

- Moo::Roleの`requires`で必須メソッドを宣言でき、実装漏れを防げる
- Strategyパターンとの違い：StateがContext（$self）を受け取り、状態遷移を制御する

**出典**:

- MetaCPAN: Moo::Role - https://metacpan.org/pod/Moo::Role
- MetaCPAN: Moo - https://metacpan.org/pod/Moo
- Perl Maven: OOP with Moo - https://perlmaven.com/oop-with-moo
- Moose::Manual::Concepts - https://perldoc.jp/pod/Moose::Manual::Concepts

**信頼度**: 9/10

---

## 4. 競合記事の分析

### 4.1 日本語の主要記事

| 記事タイトル | URL | 特徴 | 差別化ポイント |
|-------------|-----|------|---------------|
| デザインパターン Stateパターン（Qiita） | https://qiita.com/AsahinaKei/items/ce8e5d7bc375af23c719 | エアコン制御の実例、Java中心 | Java特化、Perl非対応 |
| GoF 23パターン State編（Qiita） | https://qiita.com/Pentaro256/items/752f28aa425c4295b13d | GoF準拠、体系的解説 | 網羅的だが実践例少なめ |
| 今さら聞けないステートパターン（Zenn） | https://zenn.dev/nekoniki/articles/b039e5e553b5e95729b5 | TypeScript実装、犬の状態例 | Web系向け、Perl非対応 |
| デザインパターンを学ぶ #17 ステート（Zenn） | https://zenn.dev/tajicode/articles/aa18feba9a570f | 段階的解説、初心者向け | Perl非対応 |
| State パターン（TECHSCORE） | https://www.techscore.com/tech/DesignPattern/State | 入門向け、シンプル | 古い記事、モダン言語非対応 |
| State パターン（IT専科） | https://www.itsenka.com/contents/development/designpattern/state.html | 基本解説 | 実装例が少ない |
| State（Refactoring Guru 日本語） | https://refactoring.guru/ja/design-patterns/state | 図解豊富、多言語対応 | Perl無し |

### 4.2 差別化ポイントの抽出

**既存記事の問題点**:

1. **Perl/Moo特化の記事が皆無**: 日本語でPerl向けのState解説はほぼ存在しない
2. **Strategyとの比較が不十分**: 構造が似ているため混同しやすいが、違いの説明が曖昧
3. **状態遷移図との連携不足**: コードだけで状態遷移を説明しがち
4. **実践的なユースケースの不足**: 抽象的な例が多い

**本教材シリーズの強み（予定）**:

1. **Perl/Moo特化**: v5.36対応のモダンPerl記法
2. **Strategyパターンとの明確な比較**: 既存のStrategyシリーズとの連携
3. **状態遷移図との併用**: Mermaidで視覚化
4. **段階的な学習**: 「Mooで覚えるオブジェクト指向プログラミング」からの継続性
5. **実践的な題材**: 自動販売機など身近な例

**信頼度**: 9/10

---

## 5. 内部リンク調査

### 5.1 関連記事（grep調査結果）

#### State/ステート関連のヒット

| ファイルパス | 内部リンク | 関連度 |
|-------------|-----------|--------|
| `/content/post/2026/01/09/005327.md` | `/2026/01/09/005327/` | 高（Strategyシリーズ最終回でStateに言及） |
| `/content/post/2026/01/08/033715.md` | `/2026/01/08/033715/` | 要確認 |
| `/content/post/2026/01/08/033309.md` | `/2026/01/08/033309/` | 要確認 |
| `/content/post/2026/01/08/033512.md` | `/2026/01/08/033512/` | 要確認 |

#### Strategy/ストラテジー関連のヒット（比較用）

| ファイルパス | 内部リンク | 関連度 |
|-------------|-----------|--------|
| `/content/post/2026/01/09/005327.md` | `/2026/01/09/005327/` | 最高（Strategyパターン解説記事） |
| `/content/post/2026/01/03/001541.md` | `/2026/01/03/001541/` | 高（ディスパッチャーシリーズ最終回） |
| `/content/post/2025/12/07/000000.md` | `/2025/12/07/000000/` | 中（Test2フレームワーク内でstrategy設定） |

#### デザインパターン関連のヒット

| ファイルパス | 内部リンク | 関連度 |
|-------------|-----------|--------|
| `/content/post/2025/12/25/234500.md` | `/2025/12/25/234500/` | 高 |
| `/content/post/2026/01/04/011446.md` - `/content/post/2026/01/04/011452.md` | 複数 | 高（デザインパターン関連シリーズ） |

#### Moo/オブジェクト指向関連のヒット

| ファイルパス | 内部リンク | 関連度 |
|-------------|-----------|--------|
| `/content/post/2025/12/11/000000.md` | `/2025/12/11/000000/` | **最高**（Moo/Moose解説記事） |
| `/content/post/2025/12/30/163810.md` - `/content/post/2025/12/30/163820.md` | 複数 | 高（「Mooで覚えるOOP」シリーズ全12回） |

### 5.2 推奨内部リンク一覧

#### 前提知識記事

| 記事 | 内部リンク | リンク理由 |
|-----|-----------|-----------|
| Moo/Moose解説 | `/2025/12/11/000000/` | Moo::Roleの前提知識 |
| Mooで覚えるOOP 第10回（ロール） | `/2025/12/30/163818/` | Moo::Role、withの詳細 |
| Mooで覚えるOOP 第7回（関連するデータ） | `/2025/12/30/163815/` | オブジェクトの関連（ContextがStateを持つ） |
| Mooで覚えるOOP 第12回（型チェック） | `/2025/12/30/163820/` | does制約 |

#### 比較・関連記事

| 記事 | 内部リンク | リンク理由 |
|-----|-----------|-----------|
| Strategyパターン解説（データエクスポーター最終回） | `/2026/01/09/005327/` | Strategyとの比較 |
| ディスパッチャーシリーズ最終回 | `/2026/01/03/001541/` | Strategyパターンとの関連 |
| デザインパターン概要 | `/warehouse/design-patterns-overview/` | GoFパターン全体像 |

---

## 6. 既存シリーズとの重複チェック

### 6.1 `/agents/structure/` 配下の既存シリーズ構造

| ファイル名 | 内容 | Stateパターンとの重複 |
|-----------|------|---------------------|
| `strategy-pattern-series-structure.md` | Strategyパターンシリーズ構造案 | **関連あり（比較対象）** |
| `moo-oop-series-structure.md` | Mooで覚えるOOPシリーズ構造案 | 前提知識シリーズ |
| `moo-dispatcher-series-structure.md` | ディスパッチャーシリーズ構造案 | Strategyパターン実践（別題材） |
| `command-pattern-series-structure.md` | Commandパターンシリーズ構造案 | 振る舞いパターン（別パターン） |
| `singleton-pattern-series-structure.md` | Singletonパターンシリーズ構造案 | 生成パターン（別カテゴリ） |
| `facade-pattern-series-structure.md` | Facadeパターンシリーズ構造案 | 構造パターン（別カテゴリ） |
| `adapter-pattern-series-structure.md` | Adapterパターンシリーズ構造案 | 構造パターン（別カテゴリ） |
| `iterator-pattern-series-structure.md` | Iteratorパターンシリーズ構造案 | 振る舞いパターン（別パターン） |

### 6.2 重複チェック結果

**Stateパターンを扱った既存シリーズ: なし**

既存のシリーズ構造案にStateパターンを主題としたものは存在しない。

---

## 7. まとめ

### 7.1 調査結果のサマリー

1. **Stateパターンの位置づけ**: GoF振る舞いパターンの1つ。Strategyパターンと構造は似ているが、目的と切り替え主体が異なる

2. **Strategyとの主な違い**:
   - State: 内部状態の変化に応じて自動で切り替え、状態遷移あり
   - Strategy: 外部から明示的にアルゴリズムを選択

3. **Perl/Moo実装の可能性**: Moo::Roleで状態インターフェースを定義し、各ConcreteStateがContextへの参照を持って状態遷移を制御する設計が可能

4. **既存シリーズとの重複**: Stateパターンを扱った既存シリーズはなし

---

## 参考文献・リソースリスト

### 書籍

| 書籍名 | 著者 | ISBN/ASIN | 重要度 |
|-------|------|-----------|--------|
| Design Patterns: Elements of Reusable Object-Oriented Software | GoF | 978-0201633610 | **必須** |
| Head First Design Patterns (2nd Edition) | Eric Freeman, Elisabeth Robson | 978-1492078005 | 推奨 |

### Webリソース

| リソース名 | URL | 特徴 | 信頼度 |
|-----------|-----|------|--------|
| Refactoring Guru - State（日本語） | https://refactoring.guru/ja/design-patterns/state | 視覚的な図解、多言語コード例 | ★★★★★ |
| Wikipedia - State pattern | https://en.wikipedia.org/wiki/State_pattern | 正式な定義 | ★★★★★ |
| Qiita - デザインパターン Stateパターン | https://qiita.com/AsahinaKei/items/ce8e5d7bc375af23c719 | Java実装例 | ★★★★☆ |
| Qiita - GoF 23パターン State編 | https://qiita.com/Pentaro256/items/752f28aa425c4295b13d | 体系的解説 | ★★★★☆ |
| Zenn - ステートパターン | https://zenn.dev/nekoniki/articles/b039e5e553b5e95729b5 | TypeScript実装 | ★★★★☆ |
| TECHSCORE - State パターン | https://www.techscore.com/tech/DesignPattern/State | 入門向け | ★★★★☆ |
| MetaCPAN - Moo | https://metacpan.org/pod/Moo | Perl Moo公式 | ★★★★★ |
| MetaCPAN - Moo::Role | https://metacpan.org/pod/Moo::Role | Perl Moo::Role公式 | ★★★★★ |

---

**調査完了日**: 2026年1月8日
**調査者**: 調査・情報収集エージェント

---

End of Document
