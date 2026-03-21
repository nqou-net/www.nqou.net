use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-null-object-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: 全通知あり — 正常動作' => sub {
    my $email = EmailNotifier->new(address => 'test@example.com');
    my $slack = SlackNotifier->new(channel => '#orders');
    my $logger = Logger->new;

    my $svc = NotificationService->new(
        email_notifier => $email,
        slack_notifier => $slack,
        logger         => $logger,
    );

    $svc->notify_order_placed(1, '株式会社テスト');

    is(scalar $email->sent->@*, 1, 'Email sent');
    is(scalar $slack->sent->@*, 1, 'Slack sent');
    is(scalar $logger->logs->@*, 1, 'Log recorded');
};

subtest 'Before: 通知なし（undef）— defined チェックに依存' => sub {
    # 通知不要ユーザー: すべて undef
    my $svc = NotificationService->new();

    # エラーにはならないが、defined チェックに頼っている
    $svc->notify_order_placed(2, 'テスト社');
    $svc->notify_order_shipped(2);
    $svc->notify_order_cancelled(2, 'ユーザー都合');
    $svc->notify_payment_failed(2, 'カード無効');

    ok(1, 'No crash — but only because of 12 defined checks across 4 methods');
};

subtest 'Before: 問題の証明 — defined チェック漏れは即死' => sub {
    # もし誰かが defined チェックなしで直接呼んだら…
    my $svc = NotificationService->new();

    # email_notifier は undef
    ok(!defined $svc->email_notifier, 'email_notifier is undef');
    ok(!defined $svc->slack_notifier, 'slack_notifier is undef');
    ok(!defined $svc->logger, 'logger is undef');

    # 直接呼び出しはエラー
    eval { $svc->email_notifier->send('test') };
    like($@, qr/Can't call method/, 'PROBLEM: calling send on undef crashes');

    ok(1, 'PROBLEM: Every call site must remember the defined check');
};

subtest 'Before: 防衛的コードの量を確認' => sub {
    # NotificationService のソースを読んで defined の数を数える
    open my $fh, '<', './agents/tests/code-detective-null-object-pattern/before/lib.pl'
        or die $!;
    my $source = do { local $/; <$fh> };
    close $fh;

    my @defined_checks = ($source =~ /if \(defined/g);
    cmp_ok(scalar @defined_checks, '>=', 12,
        "PROBLEM: ${\scalar @defined_checks} defined checks in the source");
};

done_testing;
