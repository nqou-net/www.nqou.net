# 構造案: コード探偵【CQRS】読み書き混在の証言台

## メタ情報

- **シリーズ**: code-detective
- **パターン**: CQRS (Command Query Responsibility Segregation)
- **アンチパターン**: Mixed Repository（読み書き混在リポジトリ）
- **slug**: `cqrs`
- **タイトル**: コード探偵ロックの事件簿【CQRS】読み書き混在の証言台〜書き込んで読めなくなったリポジトリの密室〜
- **公開日**: 2026-04-04T07:07:05+09:00

---

## 語り部プロファイル（ワトソン君）

- **名前**: 高橋サクラ（女性・28歳）
- **職種**: 社内営業支援システム バックエンドエンジニア
- **一人称**: 私
- **性格**: 几帳面で責任感が強い。仕様変更の影響範囲を正確に把握したいが、コードが複雑すぎて把握できない状態にストレスを感じる
- **背景**: 担当する`SalesOrderRepository`が肥大化。受注登録（厳密なバリデーション付き書き込み）とダッシュボード用集計クエリ（顧客別合計・保留件数・月次サマリー）が同一クラスに同居。ダッシュボード用にカラムを追加するたびに受注バリデーションの単体テストが壊れ、逆も然り
- **悩み**: 「受注ロジックを直すたびに、なぜかレポートが壊れるんです」

---

## 5幕構成プロット

### I. 導入（依頼）

**見出し案**: 営業部からのクレーム

- 高橋サクラがLCI事務所を訪問
- 「月次レポートの集計ロジックを修正したら、受注登録のバリデーションが落ちるようになりました」
- ロック: 「——告発と尋問を、同じ部屋でやっているのかね、ワトソン君」
- 「高橋です。告発じゃなくてリポジトリなんですが」
- 報酬: 「メカニカルキーボード用のパームレスト。革製で頼む」

### II. 現場検証（Beforeコード）

**見出し案**: 証言台を汚染した混在コード

- `SalesOrderRepository`のコードを確認
- `register`（バリデーション付き書き込み）と`summary`/`total_by_customer`/`pending_orders`（読み取り）が同居
- ロック: 「受注登録は告発状——正確さと不変条件が必要だ。集計クエリは証言記録——速度と柔軟性が必要だ。なぜ同じクラスに詰め込んでいる？」
- アンチパターン「Mixed Repository」を「告発担当と証言担当を一人に押しつける密室」として擬人化

**Beforeコード**:
```perl
package SalesOrderRepository;
use Moo;
use List::Util qw(sum0);

has _orders => (is => 'ro', default => sub { [] });

sub register {
    my ($self, %args) = @_;
    die "顧客IDが必要です\n"       unless $args{customer_id};
    die "金額は正の整数が必要です\n" unless ($args{amount} // 0) > 0;
    die "商品リストが必要です\n"     unless $args{items} && @{$args{items}};
    my $order = {
        id          => sprintf('ORD-%04d', scalar(@{$self->_orders}) + 1),
        customer_id => $args{customer_id},
        amount      => $args{amount},
        items       => $args{items},
        status      => 'pending',
        created_at  => time(),
    };
    push @{$self->_orders}, $order;
    return $order;
}

sub complete_order {
    my ($self, $order_id) = @_;
    my ($order) = grep { $_->{id} eq $order_id } @{$self->_orders};
    die "受注が見つかりません\n" unless $order;
    $order->{status} = 'completed';
    return $order;
}

sub total_by_customer {
    my ($self, $customer_id) = @_;
    return sum0(map  { $_->{amount} }
                grep { $_->{customer_id} eq $customer_id } @{$self->_orders});
}

sub pending_orders {
    my ($self) = @_;
    return grep { $_->{status} eq 'pending' } @{$self->_orders};
}

sub summary {
    my ($self) = @_;
    my @orders = @{$self->_orders};
    return {
        count   => scalar @orders,
        total   => sum0(map { $_->{amount} } @orders),
        pending => scalar(grep { $_->{status} eq 'pending' } @orders),
    };
}
```

### III. 推理披露（CQRS適用）

**見出し案**: 告発台と証言台の分離

- CQRSの核心: CommandとQueryは目的が違う
  - Command: 状態を変える。業務ルールの不変条件を守る責任がある
  - Query: 状態を読む。効率的な参照に最適化する責任がある
- 「書いて状態を変える者と、読んで事実を伝える者は、話す言葉が違う。同じ部屋に入れてはいけない」
- `SalesOrderCommandRepository`（書き込み専用・バリデーション有）と`SalesOrderQueryService`（読み取り専用・集計特化）に分離

**Afterコード（Command側）**:
```perl
package SalesOrder;
use Moo;
use Types::Standard qw(Str Int ArrayRef);
has id          => (is => 'ro', isa => Str, required => 1);
has customer_id => (is => 'ro', isa => Str, required => 1);
has amount      => (is => 'ro', isa => Int, required => 1);
has items       => (is => 'ro', isa => ArrayRef, required => 1);
has status      => (is => 'rw', default => 'pending');
has created_at  => (is => 'ro', required => 1);

package SalesOrderCommandRepository;
use Moo;
has _store => (is => 'ro', default => sub { [] });

sub register { ... }  # バリデーション付き書き込みのみ
sub complete  { ... }  # ステータス変更のみ
sub all { return @{$_[0]->_store} }
```

**Afterコード（Query側）**:
```perl
package SalesOrderQueryService;
use Moo;
use List::Util qw(sum0);
has _command_repo => (is => 'ro', required => 1);

sub total_by_customer { ... }  # 集計クエリのみ
sub pending_orders    { ... }  # フィルタのみ
sub summary           { ... }  # サマリーのみ
```

### IV. 解決（テスト通過）

**見出し案**: 二つの部屋で証言は整う

- テスト通過
- 「バリデーションを変えてもQueryServiceのテストは影響を受けない」
- 「集計ロジックを変えてもCommandRepositoryのバリデーションは安全だ」
- ビルド緑点灯 → 事件解決

### V. 報告書（探偵の調査報告書）

**見出し案**: LCI調査報告書 — 事件番号0404

- 事件の概要
- 技術対応表
- ワトソン君へのメッセージ: 「次はEvent Sourcing（前回の事件）とCQRSの組み合わせも調べたまえ。相性が良い」

---

## フロントマター（暫定）

```yaml
title: "コード探偵ロックの事件簿【CQRS】読み書き混在の証言台〜書き込んで読めなくなったリポジトリの密室〜"
date: 2026-04-04T07:07:05+09:00
draft: true
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - cqrs
  - mixed-repository
  - refactoring
  - code-detective
```

---

## コードファイル構成

```
agents/tests/code-detective-cqrs/
├── before/
│   └── lib.pl
├── after/
│   └── lib.pl
└── t/
    ├── before.t
    └── after.t
```
