# 構造案: コード探偵ロックの事件簿【Double Dispatch】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Double Dispatch】二人の容疑者の対面尋問〜型の組み合わせが生む死角〜 |
| パターン | Double Dispatch |
| アンチパターン | Type Checking Chains（型チェックの連鎖） |
| slug | double-dispatch |
| 公開日時 | 2026-04-08T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/08/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 宮本 彩（みやもと あや） |
| 年齢 | 26歳 |
| 職種 | ECプラットフォームの決済基盤チームエンジニア |
| 一人称 | 私 |
| 性格 | 勤勉で真っ直ぐだが、複雑な問題に当たると視野が狭くなりがち。追い詰められると冷静さを保とうとして逆に早口になる |
| 背景 | 注文種別（通常注文・定期購入・予約注文）と決済方法（クレジットカード・銀行振込・コンビニ払い）の組み合わせで処理が異なるシステムを担当。新しい組み合わせを追加するたびにif/elsif文が倍々で増殖し、先月の「定期購入 × コンビニ払い」追加時に既存の「通常注文 × 銀行振込」のロジックを壊してしまった。修正のつもりが別の組み合わせを壊す悪循環に陥っている |

---

## コード設計

### Beforeコード（アンチパターン: Type Checking Chains）

`lib/PaymentProcessor.pm`

```perl
package PaymentProcessor;
use Moo;

sub process {
    my ($self, $order, $payment) = @_;

    if (ref $order eq 'NormalOrder') {
        if (ref $payment eq 'CreditCard') {
            return { method => 'credit', amount => $order->total, status => 'charged' };
        } elsif (ref $payment eq 'BankTransfer') {
            return { method => 'bank', amount => $order->total, status => 'pending', due_days => 7 };
        } elsif (ref $payment eq 'ConvenienceStore') {
            return { method => 'convenience', amount => $order->total, status => 'awaiting', expires_in => 3 };
        }
    } elsif (ref $order eq 'SubscriptionOrder') {
        if (ref $payment eq 'CreditCard') {
            return { method => 'credit', amount => $order->monthly_amount, status => 'enrolled', recurring => 1 };
        } elsif (ref $payment eq 'BankTransfer') {
            return { method => 'bank', amount => $order->monthly_amount, status => 'pending', due_days => 14, recurring => 1 };
        } elsif (ref $payment eq 'ConvenienceStore') {
            die "定期購入にコンビニ払いは未対応です";
        }
    } elsif (ref $order eq 'PreOrder') {
        if (ref $payment eq 'CreditCard') {
            return { method => 'credit', amount => 0, status => 'authorized', hold => $order->total };
        } elsif (ref $payment eq 'BankTransfer') {
            return { method => 'bank', amount => $order->total, status => 'pending', due_days => 30 };
        } elsif (ref $payment eq 'ConvenienceStore') {
            return { method => 'convenience', amount => $order->deposit, status => 'awaiting', expires_in => 7 };
        }
    }
}
```

**問題点**:
- `ref` による型チェックの二重ネスト（注文3種 × 決済3種 = 9分岐）
- 新しい注文種別や決済方法の追加で分岐が爆発的に増加
- 修正時に既存の分岐を壊しやすい（隣接するelsifに影響）
- 型チェーンが一箇所に集中し、単体テストが困難

### Afterコード（Double Dispatch）

`lib/Order/Normal.pm`

```perl
package Order::Normal;
use Moo;

has total => (is => 'ro', required => 1);

sub accept_payment {
    my ($self, $payment) = @_;
    return $payment->process_for_normal($self);
}
```

`lib/Order/Subscription.pm`

```perl
package Order::Subscription;
use Moo;

has monthly_amount => (is => 'ro', required => 1);

sub accept_payment {
    my ($self, $payment) = @_;
    return $payment->process_for_subscription($self);
}
```

`lib/Order/PreOrder.pm`

```perl
package Order::PreOrder;
use Moo;

has total   => (is => 'ro', required => 1);
has deposit => (is => 'ro', required => 1);

sub accept_payment {
    my ($self, $payment) = @_;
    return $payment->process_for_preorder($self);
}
```

`lib/Payment/CreditCard.pm`

```perl
package Payment::CreditCard;
use Moo;

sub process_for_normal {
    my ($self, $order) = @_;
    return { method => 'credit', amount => $order->total, status => 'charged' };
}

sub process_for_subscription {
    my ($self, $order) = @_;
    return { method => 'credit', amount => $order->monthly_amount, status => 'enrolled', recurring => 1 };
}

sub process_for_preorder {
    my ($self, $order) = @_;
    return { method => 'credit', amount => 0, status => 'authorized', hold => $order->total };
}
```

`lib/Payment/BankTransfer.pm`

```perl
package Payment::BankTransfer;
use Moo;

sub process_for_normal {
    my ($self, $order) = @_;
    return { method => 'bank', amount => $order->total, status => 'pending', due_days => 7 };
}

sub process_for_subscription {
    my ($self, $order) = @_;
    return { method => 'bank', amount => $order->monthly_amount, status => 'pending', due_days => 14, recurring => 1 };
}

sub process_for_preorder {
    my ($self, $order) = @_;
    return { method => 'bank', amount => $order->total, status => 'pending', due_days => 30 };
}
```

`lib/Payment/ConvenienceStore.pm`

```perl
package Payment::ConvenienceStore;
use Moo;

sub process_for_normal {
    my ($self, $order) = @_;
    return { method => 'convenience', amount => $order->total, status => 'awaiting', expires_in => 3 };
}

sub process_for_subscription {
    my ($self, $order) = @_;
    die "定期購入にコンビニ払いは未対応です";
}

sub process_for_preorder {
    my ($self, $order) = @_;
    return { method => 'convenience', amount => $order->deposit, status => 'awaiting', expires_in => 7 };
}
```

**改善点**:
- `ref` による型チェックが完全に消滅
- 注文種別の追加は新しいOrderクラスに`accept_payment`を実装するだけ
- 決済方法の追加は新しいPaymentクラスに`process_for_*`メソッド群を実装するだけ
- 各組み合わせの処理が独立したメソッドなので個別にテスト可能
- ディスパッチが2段階で行われる: 1段目はOrderの型で`accept_payment`、2段目はPaymentの型で`process_for_*`

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックは二台のモニタの間にルービックキューブを挟んで、片手で回しながらコードを読んでいる
- 宮本が「組み合わせを一つ追加したら、別の組み合わせが壊れるんです」と訪ねてくる
- ロック「ほう。二人の容疑者が互いに別の場所でアリバイを主張している——古典的な共犯崩しの問題だね、ワトソン君」
- 宮本「宮本です。共犯って、if文のことですか？」
- ロック「if文は共犯者じゃない。if文は、共犯者を見分けられない盲目の証人だよ」

### II. 現場検証（コードの指紋）

- ロックがPaymentProcessor.pmのBeforeコードを精読
- 「見たまえ。注文が3種、決済が3種。だが、この `process` メソッドは9つの分岐を一人で背負い込んでいる」
- 宮本「新しい組み合わせを追加するたびに、ここに分岐を足すしかなくて……」
- ロック「問題は `ref` だ。`ref $order eq 'NormalOrder'` という型チェックは、相手に名乗らせず、こちらから身体検査している。相手が名乗ればいいものを」
- 「真犯人は **Type Checking Chains** ——型チェックの連鎖だ。二人の容疑者の組み合わせを、第三者が外から当て推量しているから死角が生まれる」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は対面尋問だ。容疑者Aに、容疑者Bの前で自分の名を名乗らせる」
- 宮本「対面尋問……？」
- ロック「**Double Dispatch**。一段目のディスパッチで注文が自分の型を名乗り、二段目のディスパッチで決済が自分の型に応じた処理を返す。第三者の型チェックは不要になる」
- Order::Normal / Order::Subscription / Order::PreOrder の `accept_payment` を解説
- 宮本「`$payment->process_for_normal($self)` って、注文が決済に自分を渡しているんですか？」
- ロック「その通り。注文が名乗り、決済が応答する。二人が直接対面するから、第三者の推測は要らない」
- Payment::CreditCard / BankTransfer / ConvenienceStore を解説
- Mermaid図でディスパッチの流れを図示

### IV. 解決（平和なビルド）

- テストを実行。9つの組み合わせすべてが個別に検証可能に
- 「定期購入 × コンビニ払い」のエラーケースもPaymentクラス内で明示的に管理
- 宮本「新しい注文種別を追加する場合は……」
- ロック「新しいOrderクラスに`accept_payment`を追加し、各Paymentクラスに`process_for_新種別`を追加する。既存コードには触れない」
- 宮本「触れない……！ 他の組み合わせを壊す心配がない」
- ロック「報酬は、この型チェーンの深さと同じフィンガーのウイスキーでいい」
- 宮本（心の中）：「二重ネストだから二フィンガー？ それって普通の量では」

### V. 報告書（探偵の調査報告書）

- 事件概要表（容疑 → 真実 → 証拠）
- 推理のステップ（リファクタリング手順）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Double Dispatch】二人の容疑者の対面尋問〜型の組み合わせが生む死角〜"
date: "2026-04-08T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - double-dispatch
  - type-checking-chains
  - refactoring
  - code-detective
```
