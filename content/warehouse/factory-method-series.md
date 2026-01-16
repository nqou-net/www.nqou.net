---
date: 2026-01-17T03:02:53+09:00
description: Factory Methodパターンの調査結果 - 定義、適用場面、Perl/Moo実装の観点を整理
draft: true
epoch: 1768586573
image: /favicon.png
iso8601: 2026-01-17T03:02:53+09:00
tags:
  - design-patterns
  - factory-method
  - creational-patterns
  - perl
  - moo
title: Factory Methodパターン調査ドキュメント
---

# Factory Methodパターン調査ドキュメント

## 調査目的

Factory Methodパターンの定義、適用場面、Perl/Mooでの実装観点を整理し、連載企画のための基礎情報を揃える。

- **調査対象**: Factory Methodパターンの定義、用途、利点・欠点、Perl/Mooでの実装要素
- **想定読者**: Perl入学式卒業程度の初学者でMooの基礎を習得済みの読者
- **調査実施日**: 2026年1月17日

---

## 1. 概要

### 1.1 Factory Methodパターンの定義

**要点**:

- GoFの生成パターンの1つで、生成インターフェースを定義し、生成対象の決定はサブクラスに委ねる
- 生成ロジックをサブクラス側に寄せることで、クライアントを具体クラスから分離できる
- 新しい製品を追加する場合はサブクラス追加で対応でき、修正箇所を限定できる

**根拠**:

- GoF書籍と主要な解説サイトで同じ定義が採用されている

**出典**:

- Wikipedia: Factory method pattern - https://en.wikipedia.org/wiki/Factory_method_pattern
- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method
- GoF本: オブジェクト指向における再利用のためのデザインパターン (ASIN: 4797311126)

**信頼度**: 9/10（GoF原典と複数の主要解説）

---

### 1.2 Perl/Mooでの実装に必要な要素

**要点**:

- `extends`とオーバーライドでCreator/ConcreteCreatorを表現できる
- `Moo::Role`でProductの共通契約を定義できる
- `isa`や`does`で生成物の型チェックを行える

**根拠**:

- Mooの標準機能で継承とロールをサポートしている

**出典**:

- Moo - Minimalist Object Orientation - https://metacpan.org/pod/Moo
- Moo::Role - https://metacpan.org/pod/Moo::Role

**信頼度**: 8/10（公式ドキュメント）

---

### 1.3 生成パターン内での位置づけ

**要点**:

- Factory Methodは生成パターンの中でも、継承を使った拡張に強い
- PrototypeやBuilderと比べて、生成対象が単一のクラス階層である場合に向く

**根拠**:

- 生成パターンの分類表でFactory Methodが継承ベースと説明されている

**出典**:

- GeeksforGeeks: Creational Design Patterns - https://www.geeksforgeeks.org/system-design/creational-design-pattern/
- GoF本: オブジェクト指向における再利用のためのデザインパターン (ASIN: 4797311126)

**信頼度**: 8/10

---

## 2. 用途

### 2.1 具体的な利用シーン

**要点**:

| 利用シーン | 説明 | 具体例 |
|-----------|------|--------|
| プラグイン生成 | 実行時に製品種別が増える | フォーマット別エクスポーター生成 |
| UI/表示切り替え | テーマや表示形式が増える | ダーク/ライトテーマ部品の生成 |
| データ接続 | 対象が増えやすい | SQLite/MySQL接続の生成 |

**根拠**:

- 生成対象の追加が頻繁な領域で採用される

**出典**:

- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method

**信頼度**: 7/10

---

## 3. サンプルコード

### 3.1 基本的な実装例（Moo）

**要点**:

Creatorの共通処理と、ConcreteCreatorでの生成差分を最小構成で表現する。

```perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

package WidgetRole;
use v5.36;
use Moo::Role;

requires 'render';

package BaseWidgetFactory;
use v5.36;
use Moo;

sub render_widget ($self) {
    my $widget = $self->create_widget;
    return $widget->render;
}

sub create_widget ($self) {
    die 'create_widget method must be overridden in subclass';
}

package ButtonFactory;
use v5.36;
use Moo;
extends 'BaseWidgetFactory';

sub create_widget ($self) {
    return Button->new;
}

package Button;
use v5.36;
use Moo;
with 'WidgetRole';

sub render ($self) {
    return '[button]';
}

1;
```

**根拠**:

- Factory Methodの基本構造（Creator, ConcreteCreator, Product）を維持できる

**出典**:

- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method

**信頼度**: 7/10

---

## 4. 利点・欠点

### 4.1 メリット

**要点**:

| メリット | 説明 | 具体例 |
|---------|------|--------|
| 拡張に強い | 新しい製品を追加しやすい | 新しいConcreteCreatorを追加するだけでよい |
| 依存関係を減らせる | クライアントが具体クラスに依存しない | 生成対象の変更がクライアントに波及しない |

**根拠**:

- 生成の決定をサブクラスに委譲するため、修正箇所が限定される

**出典**:

- Wikipedia: Factory method pattern - https://en.wikipedia.org/wiki/Factory_method_pattern

**信頼度**: 8/10

---

### 4.2 デメリット

**要点**:

| デメリット | 説明 | 影響 | 対策 |
|-----------|------|------|------|
| クラス数が増える | 製品ごとにCreatorが必要 | 学習コストが増える | 例を絞って段階的に導入する |
| 継承依存になる | 継承が前提になる | 委譲派の設計と衝突 | 目的に応じてStrategyと使い分ける |

**根拠**:

- Creator/ConcreteCreator/Productsの階層が必須になる

**出典**:

- Refactoring Guru: Factory Method - https://refactoring.guru/design-patterns/factory-method

**信頼度**: 7/10

---

## 5. 関連記事・内部リンク

### 5.1 関連する既存記事

| 記事タイトル | リンク | 関連性 |
|-------------|--------|--------|
| 【目次】PerlとMooでレポートジェネレーターを作ってみよう（全10回） | /2026/01/12/230702/ | Factory Methodの既存シリーズ |
| シリーズ目次：Mooで覚えるオブジェクト指向プログラミング（全12回） | /2026/01/02/233311/ | 前提となるMoo基礎の確認 |
| 【目次】PerlとMooでモンスター軍団を量産してみよう（全6回） | /2026/01/17/004454/ | 生成系パターンの別シリーズ |

---

## 調査まとめ

### 主要な発見

1. Factory Methodは生成対象の決定をサブクラスに委譲することで拡張性を高める
2. Perl/Mooではextendsとオーバーライド、Moo::Roleで構造を表現できる
3. 既存のFactory Methodシリーズがあり、題材の差別化が必須

---

**作成日**: 2026年1月17日  \
**担当エージェント**: copilot  \
**保存先**: `content/warehouse/factory-method-series.md`

---

## テンプレート使用時のチェックリスト

1. [x] 各セクションに「要点」「根拠」「出典」「信頼度」が記載されている
2. [x] 出典URLが有効である
3. [x] 信頼度の根拠が明確か（1-10の10段階評価）
4. [x] 仮定がある場合は明記する
5. [x] 内部リンク候補が調査されている
6. [x] タグが英語小文字・ハイフン形式
7. [x] 提案・次のステップ・記事構成案・テーマ提案が含まれていない
