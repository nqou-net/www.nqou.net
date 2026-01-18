---
date: 2026-01-19T04:03:59+09:00
description: Abstract Factoryパターンに関する調査結果（GoFデザインパターン）
draft: false
epoch: 1768763039
image: /favicon.png
iso8601: 2026-01-19T04:03:59+09:00
tags:
  - design-patterns
  - abstract-factory
  - creational-patterns
  - perl
  - moo
title: Abstract Factoryパターン調査ドキュメント
---

# Abstract Factoryパターン調査ドキュメント

## 調査概要

- **調査目的**: Factory Methodを理解した読者が、Abstract Factoryの抽象度と設計判断を実務視点で学べるシリーズを設計するための基礎資料
- **調査実施日**: 2026年1月19日
- **技術スタック**: Perl v5.36以降 / Moo
- **想定読者**: Factory Methodと基本的なクラス設計（継承/Role/依存関係の分離）に慣れた読者
- **難易度評価**: 4/5（関連クラスが多く、抽象概念と具体実装の対応づけに慣れが必要）
- **前提知識**: Factory Methodパターンの理解、SOLIDのSRP/OCPの基礎

---

## 1. Abstract Factoryパターンの基礎

### 1.1 定義と目的

**要点**:

- Abstract FactoryパターンはGoFの生成パターンの1つ
- 「関連するオブジェクト群を生成するためのインターフェースを提供し、具体的なクラスを指定せずに一貫した製品群を作成する」
- クライアントコードを製品の具体クラスから切り離し、製品ファミリの切り替えを容易にする

**根拠**:

- GoF原典および複数の解説サイトで同一の定義が提示されている
- Factory Methodと異なり、1つの製品ではなく「製品ファミリ」全体を扱う点が強調される

**仮定**:

- 読者はFactory Methodで「生成の委譲」を理解している
- 1つの製品だけでなく複数の製品が連携する場面を想像できる

**出典**:

- Wikipedia: Abstract factory pattern - https://en.wikipedia.org/wiki/Abstract_factory_pattern
- Refactoring Guru: Abstract Factory - https://refactoring.guru/design-patterns/abstract-factory
- GoF: Design Patterns: Elements of Reusable Object-Oriented Software (ASIN: 0201633612)

**信頼度**: 9/10（GoF原典と主要技術サイトで一致）

---

### 1.2 Factory Methodとの違い

**要点**:

- Factory Methodは単一製品の生成を継承で委譲する
- Abstract Factoryは複数製品の生成を「セット」で提供する
- 製品の組み合わせを固定したい場合にAbstract Factoryが有効

**根拠**:

- Factory MethodはCreatorとProductの1対1関係が中心
- Abstract Factoryは複数Productインターフェースを束ねる

**出典**:

- Baeldung: Factory Method vs. Abstract Factory - https://www.baeldung.com/cs/factory-method-vs-abstract-factory
- Refactoring Guru: Abstract Factory - https://refactoring.guru/design-patterns/abstract-factory

**信頼度**: 8/10（複数ソースで同様の比較が提示）

---

## 2. 用途

### 2.1 具体的な利用シーン

**要点**:

| 利用シーン | 説明 | 具体例 |
|-----------|------|--------|
| UIテーマ切り替え | UI部品をテーマごとにまとめて生成 | Mac風/Windows風のボタン・ウィンドウ |
| DBドライバ切り替え | DBごとに接続/クエリオブジェクトを揃える | MySQL/PostgreSQL向けDAOセット |
| APIクライアント切り替え | 環境ごとにAPI実装を切り替える | 本番/モックAPIのクライアントセット |

**根拠**:

- UIやインフラのように製品群が必ずセットで動く場面に向く
- 製品単体を差し替える場合はFactory MethodやStrategyの方が軽量

**出典**:

- Refactoring Guru: Abstract Factory - https://refactoring.guru/design-patterns/abstract-factory
- GeeksforGeeks: Abstract Factory Pattern - https://www.geeksforgeeks.org/abstract-factory-pattern/

**信頼度**: 8/10

---

## 3. サンプルコード

### 3.1 基本的な実装例

**要点**:

- AbstractFactoryロールでcreate_button/create_windowを定義
- ConcreteFactoryがMac/Windowsなどの製品ファミリを生成
- 製品側にも共通ロールを用意し、UI側は抽象に依存する

```perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

package UIFactory;
use v5.36;
use Moo::Role;

requires qw(create_button create_window);

package MacFactory;
use v5.36;
use Moo;
with 'UIFactory';

sub create_button($self) { return MacButton->new }
sub create_window($self) { return MacWindow->new }

package WinFactory;
use v5.36;
use Moo;
with 'UIFactory';

sub create_button($self) { return WinButton->new }
sub create_window($self) { return WinWindow->new }

package MacButton;
use v5.36;
use Moo;
sub render { 'mac-button' }

package WinButton;
use v5.36;
use Moo;
sub render { 'win-button' }

1;
```

**根拠**:

- 抽象化されたファクトリを通じて製品群の切り替えが可能
- クライアントコードはFactoryとProductの抽象に依存する

**出典**:

- Refactoring Guru: Abstract Factory - https://refactoring.guru/design-patterns/abstract-factory

**信頼度**: 7/10（一般的な構成例）

---

## 4. 利点・欠点

### 4.1 メリット

**要点**:

| メリット | 説明 | 具体例 |
|---------|------|--------|
| 製品ファミリの一貫性 | 関連する製品の整合性を保てる | ボタンとウィンドウのテーマ統一 |
| 依存の分離 | クライアントが具体クラスに依存しない | UI層が抽象Factoryに依存 |
| OCPに強い | 新しい製品ファミリ追加が容易 | MacFactory追加でUIテーマ追加 |

**根拠**:

- 製品群の差し替えが一箇所で完結し、変更点が局所化される

**出典**:

- Wikipedia: Abstract factory pattern - https://en.wikipedia.org/wiki/Abstract_factory_pattern

**信頼度**: 8/10

---

### 4.2 デメリット

**要点**:

| デメリット | 説明 | 影響 | 対策 |
|-----------|------|------|------|
| クラス数の増加 | 製品×ファミリ分のクラスが必要 | 実装が冗長化 | 製品種類を絞る |
| 新しい製品種の追加が高コスト | すべてのFactoryに追加実装が必要 | 変更範囲が広い | バリエーションを固定する |
| 抽象化の重さ | 単純な場面では過剰設計になる | 学習難易度が上がる | Factory Methodで十分か検討 |

**根拠**:

- 製品ファミリ追加と製品種追加で変更コストの方向が逆になる
- 仕様変更が頻繁なプロジェクトでは保守負荷が増える

**出典**:

- Refactoring Guru: Abstract Factory - https://refactoring.guru/design-patterns/abstract-factory
- Baeldung: Factory Method vs. Abstract Factory - https://www.baeldung.com/cs/factory-method-vs-abstract-factory

**信頼度**: 8/10

---

## 5. 関連記事・内部リンク

### 5.1 関連する既存記事

| 記事タイトル | リンク | 関連性 |
|-------------|--------|--------|
| Factory Methodパターンの目次（APIレスポンスシミュレーター） | /2026/01/17/132411/ | Abstract Factoryの前提となるFactory Method理解に直結 |
| これがFactory Methodパターンだ！ | /2026/01/17/132354/ | Factory Methodの定義と構造の復習に有効 |
| Prototypeパターン最終回 | /2026/01/17/004437/ | 生成パターンの比較と次の学習先として関連 |

---

## 調査まとめ

### 主要な発見

1. Abstract Factoryは「製品ファミリの一貫性」を守るためのパターンであり、単体生成とは狙いが異なる
2. Factory Methodより抽象度が高く、難易度が上がる理由は製品群の関係を理解する必要があるため
3. 製品種の追加コストが高いため、適用条件を誤ると過剰設計になりやすい

---

**作成日**: 2026年1月19日
