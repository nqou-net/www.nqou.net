# 構造案: コード探偵【Event Sourcing】消えた在庫の証拠品

## メタ情報

- **シリーズ**: code-detective
- **パターン**: Event Sourcing
- **アンチパターン**: Lost History（消えた履歴）/ Mutable State（可変状態の直書き）
- **slug**: `event-sourcing`
- **タイトル**: コード探偵ロックの事件簿【Event Sourcing】消えた在庫の証拠品〜上書きが奪う真実と時を遡る捜査〜
- **公開日**: 2026-04-03T07:07:05+09:00

---

## 語り部プロファイル（ワトソン君）

- **名前**: 柴田リョウ（男性・30代前半）
- **職種**: ECサービス バックエンドエンジニア（在庫管理システム担当）
- **一人称**: 俺
- **性格**: 真面目で几帳面。数字が合わないことに強いストレスを感じる。技術力はあるが、「状態の設計」についての経験は浅い
- **背景**: ECサイトの在庫数が実際の出荷・入荷データと合わない。DBには`stock = 42`という現在値しかなく、「どうやって42になったか」を追跡できない。社内監査部門から「過去30日の在庫変動の根拠を出せ」と詰められているが、データがない
- **悩み**: `UPDATE items SET stock = ? WHERE id = ?` で上書きしているため、履歴が一切残っていない

---

## 5幕構成プロット

### I. 導入（依頼）

**見出し案**: 在庫課からのSOS

- 舞台: LCI事務所（雑居ビル3F、エナジードリンク缶が山積み）
- 柴田リョウが訪問。「在庫数が合わない。監査に証拠を出せと言われているが、DBには今の数字しかない」
- ロックは目を閉じたまま「数字は残っている。しかし出来事が消えているんだろう、ワトソン君」と即座に看破
- 報酬の要求: 「キーキャップ一式、Cherry MX 赤軸で頼む」
- 柴田は「なぜ俺がワトソン君なんですか？」とツッコむ

### II. 現場検証（Beforeコード）

**見出し案**: 上書きされた犯行現場

- ロックが在庫管理コードを調べる
- `Item`クラスが`stock`を`rw`で持ち、`add_stock`/`reduce_stock`が直接上書き
- 「犯行現場を毎回消して、今の状態だけを残す。これは証拠隠滅だよ、ワトソン君」
- アンチパターン「Lost History / Mutable State」を「現場を焼いてしまう犯人」として擬人化
- 柴田: 「でも…速いし、シンプルですよね」→ ロック: 「犯人が一人なら、それでいい。だが現実は？」

**Beforeコード**（`lib/Item.pm`）:
```perl
package Item;
use Moo;

has id    => (is => 'ro', required => 1);
has name  => (is => 'ro', required => 1);
has stock => (is => 'rw', default => 0);

sub add_stock {
    my ($self, $qty) = @_;
    $self->stock($self->stock + $qty);
    return;
}

sub reduce_stock {
    my ($self, $qty) = @_;
    die "在庫不足" if $self->stock < $qty;
    $self->stock($self->stock - $qty);
    return;
}
```

### III. 推理披露（Event Sourcing 適用）

**見出し案**: 出来事を積み重ねる推理

- ロックが「事件ノート（イベントログ）」の比喩でEvent Sourcingを説明
  - 「優秀な探偵は現場を変えない。出来事を記録するだけだ。状態は、その記録から演繹する」
- `StockEvent`クラス（型・数量・発生時刻）の導入
- `Item`クラスを`events`の配列を保持するように改造
- `stock()`メソッドが全イベントをreplayして現在値を計算する
- **キーポイント**: `stock($timestamp)`で「あの時点の在庫」を復元できる
- 柴田: 「え、過去の任意の時点の在庫が計算できるんですか？」→ ロック: 「出来事を消していなければ、時間などただの変数に過ぎない」

**Afterコード**:
```perl
# lib/StockEvent.pm
package StockEvent;
use Moo;
use Types::Standard qw(Str Int);

has type        => (is => 'ro', isa => Str, required => 1);  # 'added' | 'reduced'
has quantity    => (is => 'ro', isa => Int, required => 1);
has occurred_at => (is => 'ro', isa => Int, required => 1);

1;

# lib/Item.pm
package Item;
use Moo;
use Types::Standard qw(Str ArrayRef);

has id     => (is => 'ro', isa => Str, required => 1);
has name   => (is => 'ro', isa => Str, required => 1);
has events => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub stock {
    my ($self, $upto) = @_;
    my $total = 0;
    for my $e (@{ $self->events }) {
        last if defined $upto && $e->occurred_at > $upto;
        $total += $e->quantity if $e->type eq 'added';
        $total -= $e->quantity if $e->type eq 'reduced';
    }
    return $total;
}

sub add_stock {
    my ($self, $qty) = @_;
    push @{ $self->events }, StockEvent->new(
        type        => 'added',
        quantity    => $qty,
        occurred_at => time(),
    );
    return $self;
}

sub reduce_stock {
    my ($self, $qty) = @_;
    die "在庫不足" if $self->stock < $qty;
    push @{ $self->events }, StockEvent->new(
        type        => 'reduced',
        quantity    => $qty,
        occurred_at => time(),
    );
    return $self;
}

1;
```

### IV. 解決（テスト通過）

**見出し案**: 緑に点灯する真実

- テストが全てパス
- `stock_at($timestamp)`で任意時点の在庫が取得できることを実証
- 柴田: 「これで監査部門に30日分の在庫変動を提出できる…」
- ロック: 「出来事は嘘をつかない。我々が嘘をついていなければね」
- ビルドが緑に点灯 → 事件解決

### V. 報告書（探偵の調査報告書）

**見出し案**: LCI調査報告書 — 事件番号0403

- 事件の概要
- 技術対応表（アンチパターン ↔ デザインパターン）
- ワトソン君へのメッセージ: 「次はスナップショットという概念も調べたまえ。再生コストが高くなったときの切り札だ」

---

## フロントマター（暫定）

```yaml
title: "コード探偵ロックの事件簿【Event Sourcing】消えた在庫の証拠品〜上書きが奪う真実と時を遡る捜査〜"
date: 2026-04-03T07:07:05+09:00
draft: true
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - event-sourcing
  - lost-history
  - refactoring
  - code-detective
```

---

## コードファイル構成

```
agents/tests/code-detective-event-sourcing/
├── lib/
│   ├── StockEvent.pm
│   └── Item.pm
└── t/
    └── item_event_sourcing.t
```
