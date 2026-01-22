#!/usr/bin/env perl
use v5.36;

# --- 製品クラス（国内） ---
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

# --- 製品クラス（海外） ---
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

# --- 抽象Factoryロール ---
package OrderFlowFactory;
use v5.36;
use Moo::Role;

requires 'create_payment';
requires 'create_shipping';
requires 'create_notification';

# --- 国内向けFactory ---
package DomesticOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) {
    return DomesticPayment->new(%args);
}

sub create_shipping ($self, %args) {
    return DomesticShipping->new(%args);
}

sub create_notification ($self, %args) {
    return DomesticNotification->new(%args);
}

# --- 海外向けFactory ---
package GlobalOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) {
    return GlobalPayment->new(%args);
}

sub create_shipping ($self, %args) {
    return GlobalShipping->new(%args);
}

sub create_notification ($self, %args) {
    return GlobalNotification->new(%args);
}

# --- メイン処理 ---
package main;
use v5.36;

sub process_order ($factory, $order_id, $amount, $address, $email) {
    say "=" x 50;
    say "注文処理開始: $order_id";
    say "=" x 50;

    my $payment = $factory->create_payment(amount => $amount);
    my $shipping = $factory->create_shipping(address => $address);
    my $notification = $factory->create_notification(email => $email);

    my $total = $payment->process;
    say "";
    my $delivery_info = $shipping->ship;
    say "";
    $notification->notify($order_id);

    say "";
    say "=" x 50;
    say "注文処理完了";
    say "=" x 50;
    say "";
}

# 国内注文
my $domestic_factory = DomesticOrderFlowFactory->new;
process_order($domestic_factory, 'ORD-2026-0005', 5000, '東京都渋谷区1-2-3', 'tanaka@example.com');

# 海外注文
my $global_factory = GlobalOrderFlowFactory->new;
process_order($global_factory, 'ORD-2026-0006', 100, '123 Main St, New York, NY', 'john@example.com');
