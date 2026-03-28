# 構造案: コード探偵ロックの事件簿【Saga】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Saga】連鎖する犯行と償いの記録〜巻き戻せないトランザクションの迷宮〜 |
| パターン | Saga（Orchestration型 / 補償トランザクション） |
| アンチパターン | No Compensation（補償なき分散処理）——複数ステップの処理で途中失敗しても巻き戻し手順がなく、不整合な状態が残る |
| slug | saga |
| 公開日時 | 2026-04-11T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/11/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 中村 拓也（なかむら たくや） |
| 年齢 | 31歳 |
| 職種 | ECサイトのバックエンドエンジニア |
| 一人称 | 僕 |
| 性格 | 生真面目で責任感が強い。障害対応で徹夜続きだが、根本原因を突き止められずに焦っている |
| 背景 | 社内ECサイトの注文処理を担当。注文フローは「決済→在庫引当→配送手配」の3ステップで構成されるが、在庫引当や配送手配が失敗しても決済だけが成功してしまい、「お金だけ引かれて商品が届かない」という障害が週に数件発生している。各ステップは独立したサービスだが、全体を一つのトランザクションで包む手段がなく、途中失敗時の巻き戻しロジックも存在しない |

---

## コード設計

### Beforeコード（アンチパターン: 補償なき分散処理）

`lib/OrderProcessor.pm`（Before）

```perl
package OrderProcessor;
use Moo;

has payment_service   => (is => 'ro', required => 1);
has inventory_service => (is => 'ro', required => 1);
has shipping_service  => (is => 'ro', required => 1);

sub process_order {
    my ($self, $order) = @_;

    # Step 1: 決済
    my $payment = $self->payment_service->charge($order->{amount});

    # Step 2: 在庫引当
    my $reservation = $self->inventory_service->reserve($order->{item_id}, $order->{quantity});

    # Step 3: 配送手配
    my $shipment = $self->shipping_service->schedule($order->{address});

    return { payment => $payment, reservation => $reservation, shipment => $shipment };
}
```

**問題点**:
- Step 2 で在庫引当が失敗しても、Step 1 の決済は取り消されない（お金だけ引かれる）
- Step 3 で配送手配が失敗しても、決済と在庫引当は巻き戻されない
- 各ステップは成功前提で直列実行されるだけで、失敗時の補償ロジックが一切ない
- 障害が起きるたびに手動でDB修正や返金処理が必要になる

### Afterコード（Saga: 補償トランザクション付きオーケストレーション）

`lib/OrderSaga.pm`（After）

```perl
package OrderSaga;
use Moo;

has payment_service   => (is => 'ro', required => 1);
has inventory_service => (is => 'ro', required => 1);
has shipping_service  => (is => 'ro', required => 1);

sub execute {
    my ($self, $order) = @_;

    my @completed_steps;

    # Step 1: 決済
    my $payment = eval { $self->payment_service->charge($order->{amount}) };
    if ($@) {
        return { success => 0, error => "Payment failed: $@", step => 'payment' };
    }
    push @completed_steps, { name => 'payment', compensate => sub { $self->payment_service->refund($payment->{id}) } };

    # Step 2: 在庫引当
    my $reservation = eval { $self->inventory_service->reserve($order->{item_id}, $order->{quantity}) };
    if ($@) {
        $self->_compensate(\@completed_steps);
        return { success => 0, error => "Inventory failed: $@", step => 'inventory' };
    }
    push @completed_steps, { name => 'inventory', compensate => sub { $self->inventory_service->release($reservation->{id}) } };

    # Step 3: 配送手配
    my $shipment = eval { $self->shipping_service->schedule($order->{address}) };
    if ($@) {
        $self->_compensate(\@completed_steps);
        return { success => 0, error => "Shipping failed: $@", step => 'shipping' };
    }

    return { success => 1, payment => $payment, reservation => $reservation, shipment => $shipment };
}

sub _compensate {
    my ($self, $steps) = @_;
    for my $step (reverse @$steps) {
        eval { $step->{compensate}->() };
        warn "Compensation failed for $step->{name}: $@" if $@;
    }
}
```

**改善点**:
- 各ステップの成功後に「償いの手順（補償トランザクション）」を登録
- 途中ステップが失敗したら、完了済みステップを逆順に補償（決済→返金、在庫→解放）
- 全体の整合性が自動的に保たれ、手動修正が不要
- 補償自体が失敗した場合も warn でログを残し、運用で検知可能

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックはエナジードリンクの缶でドミノを並べている
- 中村が「決済だけ成功して商品が届かないんです。週に何件も」と駆け込む
- ロック「ほう。犯行は実行されたが、償いの手順が用意されていない——典型的な未解決事件だね、ワトソン君」
- 中村「中村です。犯行って、僕たちの注文処理のことですか？」
- ロック「三段階の犯行が計画されている。だが計画には、失敗したときの後始末が含まれていない。証拠を見せたまえ」

### II. 現場検証（コードの指紋）

- ロックが OrderProcessor.pm を精読
- 「見たまえ。決済、在庫引当、配送手配——三つの犯行が直列に並んでいる。だが在庫引当が失敗したとき、決済はどうなる？」
- 中村「……そのまま残ります」
- ロック「つまり被害者のお金だけが消え、商品は届かない。犯行は途中で止まっても、すでに実行された部分は巻き戻されない。これが今回の事件の構造だ」
- Mermaid図で「決済OK → 在庫NG → 決済は残ったまま」の不整合を可視化
- 「初歩的なにおいだよ、ワトソン君。**No Compensation（償いなき犯行）**——失敗時の巻き戻しが存在しない分散処理だ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は、各犯行に**償いの手順**を仕込むことだ。**Saga パターン**という」
- 中村「サーガ……？ 北欧神話の？」
- ロック「物語の連なりだよ。各章が独立しているが、全体で一つの物語を成す。そして重要なのは、どの章からでも巻き戻せる仕組みがあることだ」
- After の OrderSaga を実装・解説
- 各ステップの `compensate` クロージャの仕組みを丁寧に解説
- `_compensate` が逆順で巻き戻す理由を説明

### IV. 解決（平和なビルド）

- テストを実行。在庫引当失敗時に決済が自動返金されることを確認
- 配送手配失敗時に決済返金＋在庫解放が逆順で実行されることを確認
- 全ステップ成功時は補償なしで正常完了
- 中村「失敗しても自動で巻き戻される……！ お客様のお金が宙に浮くことがない」
- ロック「報酬は、この注文フローのステップ数と同じ杯数のエスプレッソでいい」
- 中村（心の中）：「三ステップだから三杯か。今回はちょっと多いな……」

### V. 報告書（探偵の調査報告書）

- 事件概要表（容疑: No Compensation → 真実: Saga → 証拠: 自動補償による整合性回復）
- 推理のステップ（リファクタリング手順）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Saga】連鎖する犯行と償いの記録〜巻き戻せないトランザクションの迷宮〜"
date: "2026-04-11T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - saga
  - no-compensation
  - refactoring
  - code-detective
```
