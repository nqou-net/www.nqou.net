#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

subtest 'コード例1 - 問題版 (Hardcoded Instantiation)' => sub {
    require 'example1_problem.pl';
    
    my $service = OrderService->new();
    
    # 正常系のテスト
    is(
        $service->complete_order('001', 'email'),
        'Email sent: Order 001 has been completed.',
        'email notification should work'
    );
    is(
        $service->complete_order('002', 'sms'),
        'SMS sent: Order 002 has been completed.',
        'sms notification should work'
    );
    is(
        $service->complete_order('003', 'slack'),
        'Slack message sent: Order 003 has been completed.',
        'slack notification should work'
    );
    
    # 異常系のテスト
    eval {
        $service->complete_order('004', 'line');
    };
    like($@, qr/Unknown notification type: line/, 'should croak on unknown type');
};

subtest 'コード例2 - 改善版 (Factory Method)' => sub {
    require 'example1_solution.pl';
    
    # Factoryを作成してServiceに注入
    my $factory = NotifierFactory->new();
    my $service = OrderService->new( notifier_factory => $factory );
    
    # 正常系のテスト
    is(
        $service->complete_order('101', 'email'),
        'Email sent: Order 101 has been completed.',
        'email notification should work via factory'
    );
    is(
        $service->complete_order('102', 'sms'),
        'SMS sent: Order 102 has been completed.',
        'sms notification should work via factory'
    );
    is(
        $service->complete_order('103', 'slack'),
        'Slack message sent: Order 103 has been completed.',
        'slack notification should work via factory'
    );
    
    # 異常系のテスト（Factoryが例外を投げることを確認）
    eval {
        $service->complete_order('104', 'line');
    };
    like($@, qr/Unknown notification type: line/, 'factory should croak on unknown type');
    
    # おまけ：テスト用のモックファクトリを作る例も書いておく
    # これがDI + Factoryの最大の強み
    package MockFactory {
        use Moo;
        sub create ($self, $type) {
            # どんなタイプでも、常にダミーのNotifierを返す
            return MockNotifier->new();
        }
    }
    package MockNotifier {
        use Moo;
        sub send ($self, $message) {
            return "Mock sent: $message";
        }
    }
    
    my $mock_factory = MockFactory->new();
    my $test_service = OrderService->new( notifier_factory => $mock_factory );
    
    is(
        $test_service->complete_order('999', 'any'),
        'Mock sent: Order 999 has been completed.',
        'service can easily use a mock factory for testing'
    );
};

done_testing;
