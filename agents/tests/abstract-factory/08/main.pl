#!/usr/bin/env perl
use v5.36;

# 第8回: 返品フロー追加のデモ（限界検証用）
# このコードは返品サービスを追加する例を示しています

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

# --- 返品クラス（国内） ---
package DomesticReturnService;
use v5.36;
use Moo;

has order_id => (is => 'ro', required => 1);

sub process_return ($self) {
    say "【国内返品】注文 " . $self->order_id . " の返品処理";
    say "  返送方法: 着払い";
    say "  返金目安: 3営業日";
    return { refund_days => 3 };
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

# --- 返品クラス（海外） ---
package GlobalReturnService;
use v5.36;
use Moo;

has order_id => (is => 'ro', required => 1);

sub process_return ($self) {
    say "【海外返品】Return for order " . $self->order_id;
    say "  Shipping: International prepaid label";
    say "  Refund ETA: 10 business days";
    return { refund_days => 10 };
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

# --- 返品クラス（EU） ---
package EUReturnService;
use v5.36;
use Moo;

has order_id => (is => 'ro', required => 1);

sub process_return ($self) {
    say "【EU返品】Retour pour commande " . $self->order_id;
    say "  Envoi: Étiquette prépayée UE";
    say "  Délai remboursement: 5 jours ouvrés";
    return { refund_days => 5 };
}

# --- 抽象Factoryロール（返品サービス追加版） ---
package OrderFlowFactory;
use v5.36;
use Moo::Role;

requires 'create_payment';
requires 'create_shipping';
requires 'create_notification';
requires 'create_return_service';  # 新しいメソッドを追加

# --- 国内向けFactory ---
package DomesticOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) { DomesticPayment->new(%args) }
sub create_shipping ($self, %args) { DomesticShipping->new(%args) }
sub create_notification ($self, %args) { DomesticNotification->new(%args) }
sub create_return_service ($self, %args) { DomesticReturnService->new(%args) }

# --- 海外向けFactory ---
package GlobalOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) { GlobalPayment->new(%args) }
sub create_shipping ($self, %args) { GlobalShipping->new(%args) }
sub create_notification ($self, %args) { GlobalNotification->new(%args) }
sub create_return_service ($self, %args) { GlobalReturnService->new(%args) }

# --- EU向けFactory ---
package EUOrderFlowFactory;
use v5.36;
use Moo;

with 'OrderFlowFactory';

sub create_payment ($self, %args) { EUPayment->new(%args) }
sub create_shipping ($self, %args) { EUShipping->new(%args) }
sub create_notification ($self, %args) { EUNotification->new(%args) }
sub create_return_service ($self, %args) { EUReturnService->new(%args) }

# --- OrderProcessor ---
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

sub process_return ($self, $order_id) {
    say "=" x 50;
    say "返品処理開始: $order_id";
    say "=" x 50;

    my $return_service = $self->factory->create_return_service(order_id => $order_id);
    my $result = $return_service->process_return;

    say "";
    say "=" x 50;
    say "返品処理完了";
    say "=" x 50;
    say "";

    return $result;
}

# --- メイン処理 ---
package main;
use v5.36;

# 国内注文と返品のテスト
my $domestic_processor = OrderProcessor->new(
    factory => DomesticOrderFlowFactory->new
);

$domestic_processor->process('ORD-2026-0010', 5000, '東京都渋谷区1-2-3', 'customer@example.com');
$domestic_processor->process_return('ORD-2026-0010');

# 海外注文と返品のテスト
my $global_processor = OrderProcessor->new(
    factory => GlobalOrderFlowFactory->new
);

$global_processor->process('ORD-2026-0011', 100, '123 Main St, New York', 'john@example.com');
$global_processor->process_return('ORD-2026-0011');

# EU注文と返品のテスト
my $eu_processor = OrderProcessor->new(
    factory => EUOrderFlowFactory->new
);

$eu_processor->process('ORD-2026-0012', 80, 'Rue de la Paix, Paris', 'marie@example.com');
$eu_processor->process_return('ORD-2026-0012');
