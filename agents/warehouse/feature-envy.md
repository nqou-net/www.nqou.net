---
date: 2026-03-29T12:00:00+09:00
description: 'Feature Envy（コードスメル/アンチパターン）に関する調査結果 - 定義、判定基準、解決策、関連スメルとの比較、Perl/Mooでの実装'
staleness_category: moderate
tags:
  - research
  - code-smell
  - feature-envy
  - refactoring
  - perl
  - moo
title: Feature Envy 調査ドキュメント
---

# Feature Envy — 調査レポート

**調査日**: 2026-03-29
**技術スタック**: Perl / Moo
**staleness_category**: moderate（アンチパターンは言語固有の実装慣習を含むため）

---

## 1. 定義と概要

### 公式定義

**Feature Envy** は、Martin Fowler と Kent Beck が共著した『Refactoring: Improving the Design of Existing Code』（1999年初版、2018年第2版）の第3章「Bad Smells in Code」で定義されたコードスメルの1つ。**Couplers**（結合に関するスメル群）に分類される。

> **定義**: あるメソッドが、自身のクラスのデータよりも、他のクラスのデータに多くアクセスしている状態。
> — Refactoring Guru / sourcemaking.com

**【事実】** Feature Envy は「メソッドが自分の属するクラスのデータよりも、別のクラスのデータをより多く使用している」ことを指す。名前の通り、メソッドが他のクラスの機能（feature）を「羨ましがっている」（envy）状態。

**【事実】** Martin Fowler は「Code Smell」という用語自体が Kent Beck との共同作業から生まれたと述べている。Fowler は「スメルはそれ自体が本質的に悪いわけではなく、より深い問題の表面的な指標」であると定義している。

**【事実】** Jeff Atwood（Coding Horror）は Feature Envy を「Between Classes（クラス間）」のスメルに分類し、「Methods that make extensive use of another class may belong in another class. Consider moving this method to the class it is so envious of.」と要約している。

### 発生の原因

- フィールドがデータクラスに移動された後、それを操作するメソッドが移動されないまま残った場合に発生しやすい
- Extract Class リファクタリング後の「やり残し」

**出典**:
- https://refactoring.guru/smells/feature-envy
- https://sourcemaking.com/refactoring/smells/feature-envy
- https://martinfowler.com/bliki/CodeSmell.html
- https://blog.codinghorror.com/code-smells/

---

## 2. 症状と判定基準

### 典型的な症状

**【事実】** 以下の症状が1つ以上該当する場合、Feature Envy の可能性が高い:

1. **アクセサ呼び出しの偏り**: メソッド内で `$other->foo`, `$other->bar`, `$other->baz` のように、他オブジェクトのアクセサ呼び出しが `$self` のそれを上回る
2. **ゲッターの連鎖**: 他オブジェクトから値を取得して自クラスで計算する処理が繰り返される
3. **引数としての他オブジェクト**: メソッドが他オブジェクトを引数として受け取り、そのオブジェクトのメソッドを大量に呼び出す

### 判定基準（ヒューリスティック）

**【推論】** 明確な数値基準は文献に存在しないが、以下が実務上のガイドライン:

| 指標 | 正常 | 注意 | Feature Envy |
|------|------|------|-------------|
| 他クラスのアクセサ呼び出し割合 | < 30% | 30-50% | > 50% |
| 他クラスのメソッドに依存する行数 | 少数 | メソッドの半分程度 | メソッドの大部分 |
| `$self` へのアクセス回数 vs `$other` へのアクセス回数 | `$self` > `$other` | 同程度 | `$self` < `$other` |

### Perl/Moo での具体的な症状例

```perl
# Feature Envy の例: Report が Customer のデータに過度に依存
package Report;
use Moo;

has customer => (is => 'ro');

sub generate_summary {
    my ($self) = @_;
    # $self のデータをほとんど使わず、customer のデータばかり使う
    my $name    = $self->customer->name;
    my $email   = $self->customer->email;
    my $address = $self->customer->address;
    my $phone   = $self->customer->phone;
    my $tier    = $self->customer->membership_tier;

    return sprintf("Customer: %s (%s)\nAddress: %s\nPhone: %s\nTier: %s",
        $name, $email, $address, $phone, $tier);
}
```

---

## 3. 解決策（Move Method、Extract Method 等）

### 基本原則

**【事実】** Refactoring Guru / sourcemaking.com の共通指針:

> 「同時に変更されるものは、同じ場所に置くべきである。通常、データとそのデータを使う関数は一緒に変更される（例外はあるが）。」

### 3.1 Move Method（メソッドの移動）

最も直接的な解決策。メソッドが明らかに別のクラスに属すべき場合に適用。

```perl
# Before: Feature Envy
package Report;
use Moo;
has customer => (is => 'ro');

sub customer_summary {
    my ($self) = @_;
    return sprintf("%s (%s), Tier: %s",
        $self->customer->name,
        $self->customer->email,
        $self->customer->membership_tier);
}

# After: Move Method で Customer に移動
package Customer;
use Moo;
has name            => (is => 'ro');
has email           => (is => 'ro');
has membership_tier => (is => 'ro');

sub summary {
    my ($self) = @_;
    return sprintf("%s (%s), Tier: %s",
        $self->name, $self->email, $self->membership_tier);
}

# Report は delegation で利用
package Report;
use Moo;
has customer => (
    is      => 'ro',
    handles => ['summary'],  # Customer#summary を委譲
);
# $report->summary で呼び出し可能
```

### 3.2 Extract Method（メソッドの抽出）

メソッドの一部だけが他クラスのデータにアクセスしている場合、その部分を抽出して適切なクラスに移動する。

```perl
# Before: メソッドの一部が Feature Envy
package OrderProcessor;
use Moo;

sub process {
    my ($self, $order) = @_;

    # ── この部分は自クラスの責務 ──
    $self->validate($order);

    # ── この部分は Customer への Feature Envy ──
    my $discount = 0;
    if ($order->customer->membership_tier eq 'gold') {
        $discount = 0.1;
    } elsif ($order->customer->membership_tier eq 'platinum') {
        $discount = 0.2;
    }
    my $final = $order->total * (1 - $discount);

    $self->finalize($order, $final);
}

# After: Extract Method → Move Method
package Customer;
use Moo;
has membership_tier => (is => 'ro');

sub discount_rate {
    my ($self) = @_;
    my %rates = (gold => 0.1, platinum => 0.2);
    return $rates{$self->membership_tier} // 0;
}
```

### 3.3 データと振る舞いの凝集

**【事実】** Feature Envy の根本原因は「データと振る舞いの分離」。OOP の基本原則——データとそれを操作するメソッドを同じクラスに凝集させる——に立ち返ることが本質的な解決策。

### 3.4 例外: 意図的な分離が許容されるケース

**【事実】** Refactoring Guru は以下のケースでは Feature Envy を無視してよいと明記:

- **Strategy パターン**: 振る舞いを動的に切り替えるため、意図的にデータから分離
- **Visitor パターン**: 操作をクラス階層の外に置くことで、既存クラスを変更せず機能追加
- **関数型スタイル**: データ変換パイプラインなど、データと処理の分離が自然な場合

**出典**:
- https://refactoring.guru/smells/feature-envy
- https://sourcemaking.com/refactoring/smells/feature-envy
- https://metacpan.org/pod/Moose::Manual::Delegation

---

## 4. 関連するコードスメルとの比較

Feature Envy は **Couplers**（結合系スメル）に分類される。同カテゴリの他のスメルとの比較:

| スメル | 定義 | Feature Envy との関係 |
|--------|------|----------------------|
| **Feature Envy** | メソッドが他クラスのデータに過度にアクセス | — |
| **Inappropriate Intimacy** | 2つのクラスが互いの内部に過度に依存 | Feature Envy の**双方向版**。Feature Envy は片方向 |
| **Message Chains** | `$a->b()->c()->d()` のような連鎖呼び出し | Feature Envy の**手段**。チェーンを辿って他クラスのデータに到達する過程で発生 |
| **Middle Man** | クラスが自分では何もせず、すべてを他に委譲 | Feature Envy の**過剰矯正**。Move Method をやりすぎると発生 |

### 4.1 Inappropriate Intimacy との違い

**【事実】** Inappropriate Intimacy は「1つのクラスが別のクラスの内部フィールドやメソッドを使用する」状態であり、Feature Envy よりも深刻。Feature Envy がメソッドレベルの問題であるのに対し、Inappropriate Intimacy はクラスレベルの構造的結合を指す。

### 4.2 Message Chains との関係

**【事実】** Message Chains（`$order->customer->address->city` のような連鎖）は Feature Envy の温床。ただし Message Chains の解決で Hide Delegate を過度に適用すると Middle Man が発生する。

**【推論】** 3つのスメルは振り子のように対立関係にあり、バランスが重要:

```
Message Chains ←──── バランス ────→ Middle Man
         ↑                              ↑
    Feature Envy の              Feature Envy の
    原因になりうる              過剰矯正の結果
```

### 4.3 Middle Man との関係

**【事実】** Middle Man は「Feature Envy を恐れるあまり、Message Chains の解消で overzealous になった結果」として発生しうる。クラスが自分自身の仕事を持たず、ただ委譲するだけの存在になる。

**出典**:
- https://refactoring.guru/smells/inappropriate-intimacy
- https://refactoring.guru/smells/message-chains
- https://refactoring.guru/smells/middle-man

---

## 5. 最新の議論・批判

### 5.1 コードスメルはヒューリスティックである

**【事実】** Martin Fowler 自身が明示: 「スメルは直感的に見つけやすいが、必ずしも問題を示すわけではない。長いメソッドでも問題ないものはある。」これはすべてのコードスメルに適用される原則。

### 5.2 関数型プログラミングとの緊張関係

**【推論】** 関数型プログラミングの台頭により、Feature Envy の評価は変化しつつある。関数型スタイルでは「データと振る舞いの分離」が基本設計であり、純粋関数が外部データを受け取って処理するのは正常なパターン。これは従来の OOP 視点では Feature Envy に見える。

### 5.3 マイクロサービス / DDD 文脈

**【推論】** Domain-Driven Design（DDD）の文脈では、Feature Envy は Bounded Context の境界侵犯の指標として再評価されている。あるサービスが別サービスのデータモデルに詳しすぎる場合、それは Feature Envy のアーキテクチャ版と言える。

### 5.4 「Move Method をやりすぎる」問題

**【事実】** Refactoring Guru は Feature Envy の解消で Move Method を適用する際、メソッドが複数クラスのデータを使用する場合「最もデータを多く使うクラスに置く」ことを推奨。ただし、これにより God Class が生まれるリスクもある。

**【推論】** 実務では以下の過剰矯正パターンが報告されている:
- Move Method の連鎖で特定クラスが肥大化（God Class 化）
- 過度な Committee 化で Middle Man が発生
- Strategy/Visitor の不要な導入で設計が複雑化

---

## 6. Perl/Moo での実装上の知見

### 6.1 Moo の `handles` による委譲（Delegation）

**【事実】** Moo の `handles` オプションは Feature Envy の解消に直接活用できる強力な機能。

#### 基本形: 配列による名前そのままの委譲

```perl
package Report;
use Moo;

has customer => (
    is      => 'ro',
    handles => [qw(name email membership_tier)],
);

# $report->name は $report->customer->name と等価
# Feature Envy が解消され、Report のインターフェースが簡潔に
```

#### ハッシュによるリネーム委譲

```perl
package Report;
use Moo;

has customer => (
    is      => 'ro',
    handles => {
        customer_name  => 'name',
        customer_email => 'email',
        customer_tier  => 'membership_tier',
    },
);
```

### 6.2 Move Method と Perl のパッケージシステム

**【事実】** Perl のパッケージシステムでは、メソッドの移動は単にサブルーチン定義を別パッケージに移すこと。ただし、Moo ベースのクラスでは `has` で定義した属性へのアクセスも考慮する必要がある。

### 6.3 Perl v5.36 以降の signatures 活用

```perl
# Perl v5.36+ signatures を使った明確なインターフェース
package Customer;
use v5.36;
use Moo;

has name            => (is => 'ro');
has email           => (is => 'ro');
has membership_tier => (is => 'ro');

sub discount_rate ($self) {
    my %rates = (gold => 0.1, platinum => 0.2);
    return $rates{$self->membership_tier} // 0;
}
```

---

## 7. 出典一覧

- Fowler, M. & Beck, K. (2018). *Refactoring: Improving the Design of Existing Code* (2nd ed.)
- https://refactoring.guru/smells/feature-envy
- https://sourcemaking.com/refactoring/smells/feature-envy
- https://martinfowler.com/bliki/CodeSmell.html
- https://blog.codinghorror.com/code-smells/
- https://refactoring.guru/smells/inappropriate-intimacy
- https://refactoring.guru/smells/message-chains
- https://refactoring.guru/smells/middle-man
- https://metacpan.org/pod/Moose::Manual::Delegation
