#!/usr/bin/env perl
use v5.36;

# --- 国内向けクラス ---
package DomesticPayment;
use v5.36;
use Moo;

has amount => (is => 'ro', required => 1);

sub process ($self) {
    my $fee = int($self->amount * 0.03);
    my $total = $self->amount + $fee;
    say "【国内決済】金額: ¥" . $self->amount . " + 手数料: ¥$fee = 合計: ¥$total";
    return $total;
}

package DomesticShipping;
use v5.36;
use Moo;

has address => (is => 'ro', required => 1);

sub ship ($self) {
    say "【国内配送】お届け先: " . $self->address;
    say "  配送業者: ヤマト運輸";
    say "  配送日数: 1-2営業日";
    return { carrier => 'yamato', days => 2 };
}

package DomesticNotification;
use v5.36;
use Moo;

has email => (is => 'ro', required => 1);

sub notify ($self, $order_id) {
    say "【国内通知】$order_id の注文確認メールを送信";
    say "  宛先: " . $self->email;
    say "  言語: 日本語";
    return 1;
}

# --- 海外向けクラス ---
package GlobalPayment;
use v5.36;
use Moo;

has amount => (is => 'ro', required => 1);

sub process ($self) {
    my $fee = int($self->amount * 0.05);
    my $total = $self->amount + $fee;
    say "【海外決済】Amount: \$" . $self->amount . " + Fee: \$$fee = Total: \$$total";
    return $total;
}

package GlobalShipping;
use v5.36;
use Moo;

has address => (is => 'ro', required => 1);

sub ship ($self) {
    say "【海外配送】Delivery to: " . $self->address;
    say "  Carrier: FedEx International";
    say "  Estimated: 5-10 business days";
    return { carrier => 'fedex', days => 10 };
}

package GlobalNotification;
use v5.36;
use Moo;

has email => (is => 'ro', required => 1);

sub notify ($self, $order_id) {
    say "【海外通知】Order confirmation for $order_id sent";
    say "  To: " . $self->email;
    say "  Language: English";
    return 1;
}

# --- メイン処理（バグあり） ---
package main;
use v5.36;

sub process_order_buggy ($order_id, $market, $amount, $address, $email) {
    say "=" x 50;
    say "注文処理開始: $order_id (市場: $market)";
    say "=" x 50;

    my ($payment, $shipping, $notification);

    # ★バグ: 決済だけ海外、配送と通知は国内になっている
    if ($market eq 'domestic') {
        $payment = GlobalPayment->new(amount => $amount);  # ← 間違い!
        $shipping = DomesticShipping->new(address => $address);
        $notification = DomesticNotification->new(email => $email);
    }
    elsif ($market eq 'global') {
        $payment = GlobalPayment->new(amount => $amount);
        $shipping = GlobalShipping->new(address => $address);
        $notification = GlobalNotification->new(email => $email);
    }
    else {
        die "Unknown market: $market";
    }

    my $total = $payment->process;
    say "";
    my $delivery_info = $shipping->ship;
    say "";
    $notification->notify($order_id);

    say "";
    say "=" x 50;
    say "注文処理完了";
    say "=" x 50;
}

# 国内注文を処理（しかしバグで海外決済が適用される）
process_order_buggy('ORD-2026-0003', 'domestic', 5000, '大阪市北区4-5-6', 'yamada@example.com');
