# 構造案: コード探偵ロックの事件簿【Specification】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Specification】条件迷宮の共犯者たち〜散らばったif文が隠す真実〜 |
| パターン | Specification Pattern |
| アンチパターン | Scattered Conditions（条件分岐の散在・重複） |
| slug | specification-pattern |
| 公開日時 | 2026-04-07T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/07/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 佐々木 拓也（ささき たくや） |
| 年齢 | 29歳 |
| 職種 | ECサイトのバックエンドエンジニア |
| 一人称 | 僕 |
| 性格 | 要領はいいが、複雑な条件の組み合わせに翻弄されるタイプ。追い詰められると早口になる |
| 背景 | 担当ECサイトの割引・送料無料・ポイント付与のビジネスルールが四半期ごとに増殖。条件判定が複数箇所に散在し、先週の「期間限定 × 会員ランク × 購入金額」の組み合わせ割引で、特定パターンだけ割引が適用されないバグを出してしまった。営業から「なぜこの条件だけ動かないんだ」と詰められ、原因が特定できずLCIを訪れた |

---

## コード設計

### Beforeコード（アンチパターン: Scattered Conditions）

`lib/DiscountService.pm`

```perl
package DiscountService;
use Moo;

sub calculate_discount {
    my ($self, $order) = @_;
    my $discount = 0;

    # 会員ランク割引
    if ($order->member_rank eq 'gold') {
        $discount += $order->total * 0.10;
    } elsif ($order->member_rank eq 'silver') {
        $discount += $order->total * 0.05;
    }

    # 期間限定キャンペーン
    if ($order->is_campaign_period && $order->total >= 5000) {
        $discount += 500;
    }

    # 組み合わせ割引（ゴールド会員 × キャンペーン × 1万円以上）
    if ($order->member_rank eq 'gold'
        && $order->is_campaign_period
        && $order->total >= 10000) {
        $discount += 1000;
    }

    return $discount;
}

sub is_free_shipping {
    my ($self, $order) = @_;

    # 送料無料条件（ゴールド会員 or 5000円以上）
    if ($order->member_rank eq 'gold') {
        return 1;
    }
    if ($order->total >= 5000) {
        return 1;
    }

    return 0;
}

sub calculate_points {
    my ($self, $order) = @_;
    my $points = int($order->total * 0.01);

    # ゴールド会員はポイント2倍
    if ($order->member_rank eq 'gold') {
        $points *= 2;
    }

    # キャンペーン中はさらにボーナス
    if ($order->is_campaign_period) {
        $points += 100;
    }

    return $points;
}
```

**問題点**:
- `member_rank eq 'gold'` が3箇所に散在（DRY違反）
- `is_campaign_period` の条件も複数箇所に重複
- 条件の組み合わせが増えるたびにif文がネストし、どのメソッドを修正すべきかわからなくなる
- 「ゴールド会員 × キャンペーン × 1万円以上」のような複合条件のテストが困難

### Afterコード（Specification Pattern）

`lib/Spec/Base.pm`

```perl
package Spec::Base;
use Moo;

sub is_satisfied_by {
    my ($self, $order) = @_;
    die "Must override is_satisfied_by";
}

sub and_spec {
    my ($self, $other) = @_;
    return Spec::And->new(left => $self, right => $other);
}

sub or_spec {
    my ($self, $other) = @_;
    return Spec::Or->new(left => $self, right => $other);
}

sub not_spec {
    my ($self) = @_;
    return Spec::Not->new(inner => $self);
}
```

`lib/Spec/And.pm`

```perl
package Spec::And;
use Moo;
extends 'Spec::Base';

has left  => (is => 'ro', required => 1);
has right => (is => 'ro', required => 1);

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $self->left->is_satisfied_by($order)
        && $self->right->is_satisfied_by($order);
}
```

`lib/Spec/Or.pm`

```perl
package Spec::Or;
use Moo;
extends 'Spec::Base';

has left  => (is => 'ro', required => 1);
has right => (is => 'ro', required => 1);

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $self->left->is_satisfied_by($order)
        || $self->right->is_satisfied_by($order);
}
```

`lib/Spec/Not.pm`

```perl
package Spec::Not;
use Moo;
extends 'Spec::Base';

has inner => (is => 'ro', required => 1);

sub is_satisfied_by {
    my ($self, $order) = @_;
    return !$self->inner->is_satisfied_by($order);
}
```

`lib/Spec/GoldMember.pm`

```perl
package Spec::GoldMember;
use Moo;
extends 'Spec::Base';

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $order->member_rank eq 'gold';
}
```

`lib/Spec/SilverMember.pm`

```perl
package Spec::SilverMember;
use Moo;
extends 'Spec::Base';

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $order->member_rank eq 'silver';
}
```

`lib/Spec/CampaignPeriod.pm`

```perl
package Spec::CampaignPeriod;
use Moo;
extends 'Spec::Base';

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $order->is_campaign_period;
}
```

`lib/Spec/MinimumTotal.pm`

```perl
package Spec::MinimumTotal;
use Moo;
extends 'Spec::Base';

has threshold => (is => 'ro', required => 1);

sub is_satisfied_by {
    my ($self, $order) = @_;
    return $order->total >= $self->threshold;
}
```

`lib/DiscountService.pm`（リファクタリング後）

```perl
package DiscountService;
use Moo;
use Spec::GoldMember;
use Spec::SilverMember;
use Spec::CampaignPeriod;
use Spec::MinimumTotal;

has gold_member     => (is => 'ro', default => sub { Spec::GoldMember->new });
has silver_member   => (is => 'ro', default => sub { Spec::SilverMember->new });
has campaign_period => (is => 'ro', default => sub { Spec::CampaignPeriod->new });
has min_5000        => (is => 'ro', default => sub { Spec::MinimumTotal->new(threshold => 5000) });
has min_10000       => (is => 'ro', default => sub { Spec::MinimumTotal->new(threshold => 10000) });

sub calculate_discount {
    my ($self, $order) = @_;
    my $discount = 0;

    if ($self->gold_member->is_satisfied_by($order)) {
        $discount += $order->total * 0.10;
    }
    if ($self->silver_member->is_satisfied_by($order)) {
        $discount += $order->total * 0.05;
    }

    my $campaign_min_5000 = $self->campaign_period->and_spec($self->min_5000);
    if ($campaign_min_5000->is_satisfied_by($order)) {
        $discount += 500;
    }

    my $combo_spec = $self->gold_member
        ->and_spec($self->campaign_period)
        ->and_spec($self->min_10000);
    if ($combo_spec->is_satisfied_by($order)) {
        $discount += 1000;
    }

    return $discount;
}

sub is_free_shipping {
    my ($self, $order) = @_;
    my $free_shipping_spec = $self->gold_member->or_spec($self->min_5000);
    return $free_shipping_spec->is_satisfied_by($order);
}

sub calculate_points {
    my ($self, $order) = @_;
    my $points = int($order->total * 0.01);

    if ($self->gold_member->is_satisfied_by($order)) {
        $points *= 2;
    }
    if ($self->campaign_period->is_satisfied_by($order)) {
        $points += 100;
    }

    return $points;
}
```

**改善点**:
- 各ビジネスルールが独立したSpecificationオブジェクトに凝集
- `and_spec` / `or_spec` で条件の合成が明示的・宣言的
- 新しい条件の追加は新しいSpecクラスの追加のみで完結（OCP準拠）
- 各Specificationが個別にテスト可能

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックはルーペ型のUSBメモリを磨きながら、古びたキーボードの分解清掃をしている
- 佐々木が「特定の条件の組み合わせでだけ割引が効かないバグの原因がわからないんです」と駆け込む
- ロック「ほう、条件の組み合わせか。複数の容疑者が結託して犯行に及ぶ——古典的な共犯事件だね、ワトソン君」
- 佐々木「あの、佐々木です。ワトソンではなく……」
- ロック「助手に名前は不要だ。さあ、現場の証拠品（コード）を見せたまえ」

### II. 現場検証（コードの指紋）

- ロックが DiscountService.pm のBeforeコードを精読
- 「なるほど。`member_rank eq 'gold'` という指紋が3箇所に散らばっている。これは共犯者が複数の現場に証拠を残しているのと同じだ」
- 佐々木「言われてみれば、会員ランクの判定コードがあちこちにコピペされていますね……」
- ロック「問題の本質はここだよ、ワトソン君。条件たちがバラバラに行動している。そのせいで、ある組み合わせだけ犯行計画が成立しなかった——つまり、共犯者同士の連携が取れていないんだ」
- 「ゴールド × キャンペーン × 1万円以上」の組み合わせ割引で、`is_campaign_period` のチェックが別のコードパスにあったため適用漏れが起きていた真因を特定

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は、各容疑者——いや、各条件に独立した取調室を用意することだ」
- 佐々木「取調室？」
- ロック「Specification パターンだよ。各ビジネスルールを独立したオブジェクトにカプセル化し、AND・ORで合成できるようにする。こうすれば、共犯関係が一目瞭然になる」
- Spec::Base の `is_satisfied_by`, `and_spec`, `or_spec`, `not_spec` を解説
- 佐々木「`and_spec` でつなげるだけで、組み合わせ条件が作れるんですか？」
- ロック「その通り。条件を文章のように読めるコードにするのが、このパターンの真骨頂だよ」
- Mermaid図でクラス構造を図示
- リファクタリング後の DiscountService.pm をロックが実演

### IV. 解決（平和なビルド）

- テストを実行。「ゴールド × キャンペーン × 1万円以上」の組み合わせが正しく動作することを確認
- 個々のSpecificationの単体テストもすべて緑
- 佐々木「各条件が独立しているから、テストも書きやすいですね」
- ロック「初歩的なことだよ、ワトソン君。共犯者を個別に取り調べれば、矛盾はすぐに見つかる」
- 佐々木「……僕は佐々木です」
- ロック「報酬は、散在していたif文の数と同じ年数もののスコッチでいい」
- 佐々木（心の中）：「年数もの……？ if文は10個もないのに、それでも高い気がする」

### V. 報告書（探偵の調査報告書）

- 事件概要表（容疑 → 真実 → 証拠）
- 推理のステップ（リファクタリング手順）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Specification】条件迷宮の共犯者たち〜散らばったif文が隠す真実〜"
date: "2026-04-07T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - specification-pattern
  - scattered-conditions
  - refactoring
  - code-detective
```
