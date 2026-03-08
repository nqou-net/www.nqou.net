#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

sub test_order_flow ($class_prefix) {
    # 正常系のフロー: 支払い -> 発送 -> キャンセル不可
    {
        my $order = $class_prefix->new;
        
        $order->pay();
        is($order->output->[-1], "Order paid.", "pay: success");
        
        $order->pay();
        is($order->output->[-1], "Already paid.", "pay again: invalid");
        
        $order->ship();
        is($order->output->[-1], "Order shipped.", "ship: success");
        
        $order->cancel();
        is($order->output->[-1], "Cannot cancel: Already shipped.", "cancel after ship: invalid");
    }

    # キャンセルのフロー: 未払い -> キャンセル -> 支払い不可
    {
        my $order = $class_prefix->new;
        
        $order->cancel();
        is($order->output->[-1], "Order cancelled.", "cancel unpaid: success");
        
        $order->pay();
        is($order->output->[-1], "Cannot pay: Order is cancelled.", "pay after cancel: invalid");
        
        $order->ship();
        is($order->output->[-1], "Cannot ship: Order is cancelled.", "ship after cancel: invalid");
    }

    # 返金キャンセルのフロー: 支払い -> キャンセル -> 発送不可
    {
        my $order = $class_prefix->new;
        
        $order->pay();
        is($order->output->[-1], "Order paid.", "pay: success");
        
        $order->cancel();
        is($order->output->[-1], "Order cancelled and refunded.", "cancel paid: success (refund)");
        
        $order->ship();
        is($order->output->[-1], "Cannot ship: Order is cancelled.", "ship after refund cancel: invalid");
    }
}

subtest 'コード例1 - 問題版 (Type Code)' => sub {
    require 'example1_problem.pl';
    test_order_flow('Order');
};

subtest 'コード例2 - 改善版 (State Pattern)' => sub {
    require 'example1_solution.pl';
    test_order_flow('SmartOrder');
};

done_testing;
