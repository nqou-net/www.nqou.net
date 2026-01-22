#!/usr/bin/env perl
use v5.36;

# 各クラスをインライン定義
# （実際のプロジェクトでは別ファイルに分けます）

package DomesticPayment;
use v5.36;
use Moo;

has amount => (is => 'ro', required => 1);

sub process ($self) {
    my $fee = int($self->amount * 0.03);  # 国内手数料 3%
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

package main;
use v5.36;

# 注文情報
my $order_id = 'ORD-2026-0001';
my $amount = 5000;
my $address = '東京都渋谷区1-2-3';
my $email = 'customer@example.com';

say "=" x 50;
say "注文処理開始: $order_id";
say "=" x 50;

# 1. 決済処理
my $payment = DomesticPayment->new(amount => $amount);
my $total = $payment->process;

say "";

# 2. 配送手配
my $shipping = DomesticShipping->new(address => $address);
my $delivery_info = $shipping->ship;

say "";

# 3. 完了通知
my $notification = DomesticNotification->new(email => $email);
$notification->notify($order_id);

say "";
say "=" x 50;
say "注文処理完了";
say "=" x 50;
