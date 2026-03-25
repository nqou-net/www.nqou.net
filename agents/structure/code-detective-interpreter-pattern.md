# 構造案: コード探偵【Interpreter】失われた言語の鍵

## メタ情報

- **シリーズ**: code-detective
- **パターン**: Interpreter
- **アンチパターン**: Hardcoded Business Rules（石化したビジネスルール）
- **slug**: `interpreter-pattern`
- **タイトル**: コード探偵ロックの事件簿【Interpreter】失われた言語の鍵〜硬直した規則の牢獄〜
- **公開日**: 2026-04-06T07:07:05+09:00

---

## 語り部プロファイル（ワトソン君）

- **名前**: 三島カズキ（男性・30代前半）
- **職種**: 社内ECサイト バックエンドエンジニア（プロモーション管理担当）
- **一人称**: 僕
- **性格**: 真面目で几帳面。仕様変更にも文句を言わず対応してきたが、限界が近い。技術力はあるが、設計の引き出しが少ない
- **背景**: キャンペーンのたびにマーケティング部から「この条件を追加して」と依頼が飛んでくる。割引計算ロジックが300行超のネストした`if/elsif`チェーンに膨れ上がり、改修するたびにデグレが発生。来週までに複合条件の新ルールを3つ追加しろと言われ、途方に暮れてLCIの扉を叩く
- **悩み**: 条件分岐の全容を把握している人間が退職済み。新ルール追加のたびに既存ルールが壊れる

---

## 5幕構成プロット

### I. 導入（依頼）

**見出し案**: 牢獄からの脱獄依頼

- 舞台: LCI事務所（雑居ビル3F、エナジードリンク缶とヴィンテージ技術書が散乱）
- 三島カズキが訪問。300行の`if/elsif`チェーンを印刷した紙束を抱えている
- 「来週までに割引ルールを3つ追加しろと言われたんですが、触るたびにバグが出るんです」
- ロックは紙束を一瞥し「これは…プログラムではない。古代文明が遺した暗号文書だよ、ワトソン君」
- 報酬の要求: 「Knuthの『The Art of Computer Programming』第3巻の初版があるだろう？それで手を打とう」
- カズキ: 「いや、ないですけど…あと僕はワトソンじゃ…」→ ロック:「細かいことはいい。さぁ、暗号の解読に取り掛かろう」

### II. 現場検証（Beforeコード）

**見出し案**: 文法なき暗号文書

- ロックが割引計算コードを調べる
- `DiscountCalculator`クラスに巨大な`calculate`メソッド。注文金額、会員フラグ、購入点数、キャンペーンコード等を複合的にチェックするif/elsifが延々と続く
- 「見たまえ、ワトソン君。ここには言語がない。文法がない。だから誰も読めないし、誰も正しく書き足せない」
- アンチパターン「Hardcoded Business Rules」を「鍵のない牢獄」として比喩化
  - 「ルールが壁に直接刻まれているんだ。壁を壊さなければ一文字も変えられない。これが"硬直した規則の牢獄"の正体だよ」
- カズキ: 「でも最初は3つしかルールがなくて…」→ ロック:「3つの独房でも牢獄は牢獄だ、ワトソン君」

**Beforeコード**（`lib/DiscountCalculator.pm`）:
```perl
package DiscountCalculator;
use Moo;

sub calculate {
    my ($self, $order) = @_;

    if ($order->total >= 10000 && $order->is_member) {
        return 0.15;
    }
    elsif ($order->total >= 10000) {
        return 0.10;
    }
    elsif ($order->is_member && $order->item_count >= 5) {
        return 0.08;
    }
    elsif ($order->item_count >= 3) {
        return 0.05;
    }

    return 0;
}

1;
```

補助クラス（`lib/Order.pm`）:
```perl
package Order;
use Moo;
use Types::Standard qw(Num Bool Int);

has total      => (is => 'ro', isa => Num,  required => 1);
has is_member  => (is => 'ro', isa => Bool, default  => 0);
has item_count => (is => 'ro', isa => Int,  default  => 1);

1;
```

### III. 推理披露（Interpreter パターン適用）

**見出し案**: 失われた言語を取り戻す

- ロックが「言語（文法）」を与えるという発想を披露
  - 「暗号を解くのではない。暗号に言語を与えるのだ。文法さえあれば、誰でも新しい文を書ける」
- **Expression**（抽象基底）: 全てのルール要素が持つ`evaluate`メソッド
- **Terminal Expression（終端記号）**: 単一条件を表現するクラス群
  - `AmountOver`: 注文金額が閾値以上か
  - `IsMember`: 会員か
  - `ItemCountOver`: 購入点数が閾値以上か
- **Non-terminal Expression（非終端記号）**: 条件を組み合わせるクラス群
  - `AndExpr`: 2つの式のAND
  - `OrExpr`: 2つの式のOR
- `DiscountRule`: 条件式（Expression）と割引率のペア
- `RuleEngine`: ルール一覧を走査し、最初にマッチしたルールの割引率を返す
- カズキ: 「これ、ただのクラス分けでは？」→ ロック:「君はロゼッタ・ストーンをただの石板と呼ぶのかね？」
- **キーポイント**: 新ルール追加はExpressionの組み合わせだけ。既存コードの改修不要

**Afterコード**:
```perl
# lib/Expression.pm — 抽象基底（Role）
package Expression;
use Moo::Role;
requires 'evaluate';

1;

# lib/AmountOver.pm — 終端: 金額閾値
package AmountOver;
use Moo;
use Types::Standard qw(Num);
with 'Expression';

has threshold => (is => 'ro', isa => Num, required => 1);

sub evaluate {
    my ($self, $order) = @_;
    return $order->total >= $self->threshold;
}

1;

# lib/IsMember.pm — 終端: 会員判定
package IsMember;
use Moo;
with 'Expression';

sub evaluate {
    my ($self, $order) = @_;
    return $order->is_member;
}

1;

# lib/ItemCountOver.pm — 終端: 購入点数閾値
package ItemCountOver;
use Moo;
use Types::Standard qw(Int);
with 'Expression';

has threshold => (is => 'ro', isa => Int, required => 1);

sub evaluate {
    my ($self, $order) = @_;
    return $order->item_count >= $self->threshold;
}

1;

# lib/AndExpr.pm — 非終端: AND
package AndExpr;
use Moo;
with 'Expression';

has left  => (is => 'ro', required => 1);
has right => (is => 'ro', required => 1);

sub evaluate {
    my ($self, $order) = @_;
    return $self->left->evaluate($order) && $self->right->evaluate($order);
}

1;

# lib/OrExpr.pm — 非終端: OR
package OrExpr;
use Moo;
with 'Expression';

has left  => (is => 'ro', required => 1);
has right => (is => 'ro', required => 1);

sub evaluate {
    my ($self, $order) = @_;
    return $self->left->evaluate($order) || $self->right->evaluate($order);
}

1;

# lib/DiscountRule.pm — ルール定義
package DiscountRule;
use Moo;
use Types::Standard qw(Num);

has expression => (is => 'ro', required => 1);
has rate       => (is => 'ro', isa => Num, required => 1);

sub matches {
    my ($self, $order) = @_;
    return $self->expression->evaluate($order);
}

1;

# lib/RuleEngine.pm — ルール走査エンジン
package RuleEngine;
use Moo;
use Types::Standard qw(ArrayRef);

has rules => (is => 'ro', isa => ArrayRef, required => 1);

sub calculate {
    my ($self, $order) = @_;
    for my $rule (@{ $self->rules }) {
        return $rule->rate if $rule->matches($order);
    }
    return 0;
}

1;
```

### IV. 解決（テスト通過）

**見出し案**: 解き放たれた言語

- テストが全てパス
- 既存4ルールの動作が保証される
- カズキがその場で新ルール（「会員かつ3点以上で金額5000円以上なら12%引き」）を追加してみる → 既存コードの改修なし、Expressionの組み合わせだけで実現
- カズキ: 「来週の3ルール…今すぐ追加できそうです」
- ロック: 「言語さえあれば、新しい文はいつでも書ける。牢獄の壁を壊す必要はない。鍵を手に入れればいいだけだ」
- ビルドが緑に点灯 → 事件解決

### V. 報告書（探偵の調査報告書）

**見出し案**: LCI調査報告書 — 事件番号0406

- 事件の概要
- 技術対応表（アンチパターン ↔ デザインパターン）

| 事件の証拠 | 技術的実態 | 解決の切り札 |
|---|---|---|
| 文法なき暗号文書 | 巨大if/elsifチェーン | Expression階層 |
| 壁に刻まれたルール | ハードコードされた条件 | Terminal / Non-terminal Expression |
| 牢獄の鍵 | 宣言的ルール定義 | DiscountRule + RuleEngine |

- ワトソン君へのメッセージ: 「文法が複雑になったら、パーサーの導入も検討したまえ。今回は手動で構文木を組んだが、文字列からExpressionツリーを自動構築する"翻訳機"があれば、非エンジニアでもルールを書けるようになる。それこそが真のInterpreterの完成形だよ」

---

## フロントマター（暫定）

```yaml
title: "コード探偵ロックの事件簿【Interpreter】失われた言語の鍵〜硬直した規則の牢獄〜"
date: 2026-04-06T07:07:05+09:00
draft: true
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - interpreter
  - hardcoded-business-rules
  - refactoring
  - code-detective
```

---

## コードファイル構成

```
agents/tests/code-detective-interpreter-pattern/
├── lib/
│   ├── Expression.pm
│   ├── AmountOver.pm
│   ├── IsMember.pm
│   ├── ItemCountOver.pm
│   ├── AndExpr.pm
│   ├── OrExpr.pm
│   ├── DiscountRule.pm
│   ├── RuleEngine.pm
│   ├── DiscountCalculator.pm
│   └── Order.pm
└── t/
    └── interpreter.t
```
