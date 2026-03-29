---
date: 2026-03-29T12:00:00+09:00
description: 'Law of Demeter（デメテルの法則）違反 / Train Wreck パターンに関する調査結果'
staleness_category: stable
tags:
  - research
  - law-of-demeter
  - train-wreck
  - message-chains
  - delegation
  - perl
  - moo
title: Law of Demeter（デメテルの法則）調査ドキュメント
---

# Law of Demeter（デメテルの法則）違反 / Train Wreck パターン — 調査レポート

**調査日**: 2026年3月29日
**技術スタック**: Perl / Moo

---

## 1. 公式・権威ある定義

### 1.1 Law of Demeter の起源と正式な定義

**【事実】** Law of Demeter（LoD）は1987年秋、Northeastern大学の **Ian Holland** が Demeter Project の中で提案したスタイルルールです。Karl Lieberherr が中心となって形式化・普及しました。

正式な定式化（関数のためのデメテルの法則）は、メソッド `m` がオブジェクト `a` 上で呼び出し可能なメソッドの範囲を以下に制限します：

1. `a` 自身のメソッド
2. `m` の引数のメソッド
3. `m` 内で生成されたオブジェクトのメソッド
4. `a` の属性（直接保持するオブジェクト）のメソッド
5. `m` のスコープでアクセス可能なグローバル変数のメソッド

簡潔な表現は **「直接の友人とだけ話せ。見知らぬ者とは話すな」** です。

> 出典: Wikipedia - Law of Demeter
> 出典: Karl Lieberherr - LoD General Formulation
> 出典: Lieberherr, K.J.; Holland, I.M. (1989). "Assuring good style for object-oriented programs". IEEE Software, 6(5): 38–48.

### 1.2 Train Wreck パターン（Robert C. Martin）

**【事実】** Robert C. Martin（Uncle Bob）は『Clean Code』第6章で、メソッドチェーンの連鎖 `a.getB().getC().doSomething()` を **"Train Wreck"**（列車事故）と名付けました。これは LoD 違反の典型的なコードパターンです。

ただし Martin は重要な区別を設けています：

- **オブジェクト**に対する Train Wreck → LoD 違反（内部構造の暴露）
- **データ構造**に対するドットチェイン → LoD 違反ではない（データ構造はそもそも内部を公開する目的のもの）

**【事実】** Sandi Metz は『Practical Object-Oriented Design』(2019, 2nd ed.) で LoD を「ドットは1つだけにせよ」(use only one dot) と簡潔に表現しています。

> 出典: Robert C. Martin, "Clean Code: A Handbook of Agile Software Craftsmanship", Chapter 6
> 出典: Sandi Metz, "Practical Object-Oriented Design" (2nd ed., 2019), p.81

### 1.3 Refactoring Guru: Message Chains

**【事実】** Refactoring Guru では LoD 違反を **"Message Chains"** コードスメルとして分類しています。`$a->b()->c()->d()` のような連鎖呼び出しがその典型です。

処方箋として：
- **Hide Delegate**（委譲の隠蔽）を使ってメッセージチェーンを削除
- **Extract Method** + **Move Method** で末端オブジェクトの機能をチェーン先頭に移動

> 出典: Refactoring Guru - Message Chains

### 1.4 The Paperboy, The Wallet アナロジー

**【事実】** David Bock の論文 "The Paperboy, The Wallet, and The Law Of Demeter" は LoD の最も有名な具体例です。新聞配達人が顧客の財布に直接アクセスするのではなく、顧客に支払いを要求するべきというアナロジー。

> 出典: David Bock, "The Paperboy, The Wallet, and The Law Of Demeter"

---

## 2. 最新の議論・批判・再評価

### 2.1 「法則」という名称への批判

**【事実】** Martin Fowler は LoD について：

> "I'd prefer it to be called the Occasionally Useful Suggestion of Demeter."

David Bock 自身もこれを "idiom"（慣用句）と呼んでいます。

### 2.2 ドットの数を数えるだけでは不十分

**【事実】** Phil Haack は「LoD はドットカウント演習ではない」と指摘。以下はドットが多くても LoD 違反ではない：

- **Fluent Interface**（メソッドチェーンが自身を返すパターン）
- **Value Object のチェーン**（不変オブジェクトの変換連鎖）
- **Builder パターン**

### 2.3 経験的な裏付け

**【事実】** 複数の実証研究が LoD の有用性を支持：

- **Basili et al. (1996)**: RFC が低いほどバグ発生確率が下がる。LoD に従うと RFC が低くなる傾向
- **JPL（NASAジェット推進研究所）**: Mars Pathfinder プロジェクトで、LoD を破った箇所の統合コストは少なくとも1桁高かった

---

## 3. 類似パターンとの比較・使い分け

### 3.1 Feature Envy との関連

**【事実】** LoD 違反（Message Chains）はしばしば Feature Envy の前兆あるいは共起パターンとして現れる。

| パターン | 焦点 | 問題の本質 |
|---|---|---|
| **Message Chains (LoD違反)** | オブジェクト構造への依存 | 結合度が高すぎる |
| **Feature Envy** | データとロジックの分離 | ロジックの配置場所の誤り |

**【推論】** LoD 違反を修正する際、単にメソッドを委譲するのではなく「そもそもそのロジックはどこに属すべきか」を Feature Envy の観点からも検討すべき。

### 3.2 Tell, Don't Ask 原則

**【事実】** Martin Fowler の定義：

> 「オブジェクトにデータを尋ねてそのデータに基づいて行動するのではなく、オブジェクトに何をすべきかを伝えるべき」

- **LoD**: 誰と話してよいかの制約（構造的ルール）
- **Tell, Don't Ask**: どのように話すかのスタイル（命令的 vs 質問的）

### 3.3 Middle Man（過度な委譲）との緊張関係

**【事実】** LoD 遵守 ⇔ Middle Man 化はトレードオフ関係：

```
    Message Chains ←――――→ Middle Man
    (LoD違反: 結合度↑)     (過度な委譲: 無意味な中間層)
```

> 出典: Refactoring Guru - Middle Man

---

## 4. 実装上の注意点・よくある誤用

### 4.1 LoD 準拠の利点と代償

利点：
- ソフトウェアの**保守性**と**適応性**の向上
- オブジェクト間の**疎結合**

代償：
- 大量の小さな**ラッパーメソッド**の発生
- クラスレベルでは逆に**広いインターフェース**になる可能性

### 4.2 よくある誤用パターン

| 誤用 | 問題 | 正しい対応 |
|---|---|---|
| ドットの数だけで違反を判定 | Fluent Interface 等を誤検出 | 結合度の本質を見る |
| すべてのアクセサに委譲メソッドを追加 | Middle Man 化 | データの所在とロジックの所在を再検討 |
| Value Object のチェーンまで禁止 | 不必要な間接層 | 不変オブジェクトは例外として扱う |

---

## 5. Perl/Moo での実装に関する知見

### 5.1 Moo の `handles` による委譲

**【事実】** Moo は属性宣言時に `handles` オプションで委譲を直接サポート。LoD 準拠のための最も強力な言語機能。

```perl
# 配列による name-for-name 委譲
has 'uri' => (
    is      => 'ro',
    handles => [qw( host path )],
);

# ハッシュによるリネーム委譲
has 'uri' => (
    is      => 'ro',
    handles => {
        hostname => 'host',
        path     => 'path',
    },
);
```

### 5.2 Moo と Moose の `handles` の違い

| 形式 | Moo | Moose |
|---|---|---|
| 配列リファレンス | ○ | ○ |
| ハッシュリファレンス | ○ | ○ |
| ロール名（文字列） | ○ | ○ |
| 正規表現 | × | ○ |
| カリー化 | × | ○ |

### 5.3 Perl/Moo での実践的な LoD 対応パターン

#### パターン A: 直接の `handles` 委譲

```perl
package Order;
use Moo;

has customer => (
    is      => 'ro',
    handles => [qw( customer_name customer_email )],
);
```

#### パターン B: ハッシュリネームによる Facade 的インターフェース

```perl
package Order;
use Moo;

has customer => (
    is      => 'ro',
    handles => {
        buyer_name  => 'name',
        buyer_email => 'email',
    },
);
```
