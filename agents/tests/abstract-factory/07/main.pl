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

# --- 製品クラス（EU） ---
package EUPayment;
use v5.36;
use Moo;

has amount => (is => 'ro', required => 1);

sub process ($self) {
    my $fee = int($self->amount * 0.04);
    my $total = $self->amount + $fee;
    say "【EU決済】Montant: €" . $self->amount . " + Frais: €$fee = Total: €$total";
    return $total;
}

package EUShipping;
use v5.36;
use Moo;

has address => (is => 'ro', required => 1);

sub ship ($self) {
    say "【EU配送】Livraison à: " . $self->address;
    say "  Transporteur: DHL Express";
    say "  Délai estimé: 3-5 jours ouvrés";
    return { carrier => 'dhl', days => 5 };
}

package EUNotification;
use v5.36;
use Moo;

has email => (is => 'ro', required => 1);

sub notify ($self, $order_id) {
    say "【EU通知】Confirmation de commande $order_id envoyée";
    say "  Destinataire: " . $self->email;
    say "  Langue: Français";
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

sub create_payment ($self, %args) { DomesticPayment->new(%args) }
sub create_shipping ($self, %args) { DomesticShipping->new(%args) }
sub create_notification ($self, %args) { DomesticNotification->new(%args) }

# --- 海外向けFactory ---
package GlobalOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) { GlobalPayment->new(%args) }
sub create_shipping ($self, %args) { GlobalShipping->new(%args) }
sub create_notification ($self, %args) { GlobalNotification->new(%args) }

# --- EU向けFactory（新規追加） ---
package EUOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) { EUPayment->new(%args) }
sub create_shipping ($self, %args) { EUShipping->new(%args) }
sub create_notification ($self, %args) { EUNotification->new(%args) }

# --- OrderProcessor（変更なし） ---
package OrderProcessor;
use v5.36;
use Moo;

has factory => (is => 'ro', required => 1);

sub process ($self, $order_id, $amount, $address, $email) {
    say "=" x 50;
    say "注文処理開始: $order_id";
    say "=" x 50;

    my $payment = $self->factory->create_payment(amount => $amount);
    my $shipping = $self->factory->create_shipping(address => $address);
    my $notification = $self->factory->create_notification(email => $email);

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

    return { total => $total, delivery_info => $delivery_info };
}

# --- メイン処理 ---
package main;
use v5.36;

# 3市場の一覧
my %factories = (
    domestic => DomesticOrderFlowFactory->new,
    global   => GlobalOrderFlowFactory->new,
    eu       => EUOrderFlowFactory->new,
);

# 各市場の注文を処理
for my $market (qw(domestic global eu)) {
    my $processor = OrderProcessor->new(factory => $factories{$market});
    $processor->process(
        "ORD-$market-001",
        1000,
        "Address for $market",
        "$market\@example.com"
    );
}
