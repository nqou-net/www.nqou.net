use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-null-object-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Null Object — 通知なしでも defined チェック不要' => sub {
    # 引数なし → デフォルトで NullNotifier / NullLogger が注入される
    my $svc = NotificationService->new();

    # undef は存在しない！
    ok(defined $svc->email_notifier, 'email_notifier is always defined (NullNotifier)');
    ok(defined $svc->slack_notifier, 'slack_notifier is always defined (NullNotifier)');
    ok(defined $svc->logger, 'logger is always defined (NullLogger)');

    # 直接呼び出ししてもクラッシュしない
    $svc->email_notifier->send('test');
    $svc->slack_notifier->send('test');
    $svc->logger->log('info', 'test');

    ok(1, 'FIX: No crash even without defined checks');
};

subtest 'After: Null Object — 全メソッドが安全に動作' => sub {
    my $svc = NotificationService->new();

    $svc->notify_order_placed(1, '株式会社テスト');
    $svc->notify_order_shipped(1);
    $svc->notify_order_cancelled(1, 'ユーザー都合');
    $svc->notify_payment_failed(1, 'カード無効');

    ok(1, 'FIX: All 4 methods work without any defined checks');
};

subtest 'After: 本物の通知 — 正常動作' => sub {
    my $email = EmailNotifier->new(address => 'user@example.com');
    my $slack = SlackNotifier->new(channel => '#alerts');
    my $logger = Logger->new;

    my $svc = NotificationService->new(
        email_notifier => $email,
        slack_notifier => $slack,
        logger         => $logger,
    );

    $svc->notify_order_placed(10, '株式会社タクミ');
    $svc->notify_order_shipped(10);

    is(scalar $email->sent->@*, 2, 'Email: 2 messages sent');
    is($email->sent->[0]{to}, 'user@example.com', 'Email address correct');

    is(scalar $slack->sent->@*, 2, 'Slack: 2 messages sent');
    is($slack->sent->[0]{channel}, '#alerts', 'Slack channel correct');

    is(scalar $logger->logs->@*, 2, 'Logger: 2 entries');
    is($logger->logs->[0]{level}, 'info', 'Log level correct');
};

subtest 'After: Notifier ロールのポリモーフィズム' => sub {
    ok(EmailNotifier->does('Notifier'), 'EmailNotifier does Notifier');
    ok(SlackNotifier->does('Notifier'), 'SlackNotifier does Notifier');
    ok(NullNotifier->does('Notifier'), 'NullNotifier does Notifier');

    ok(Logger->does('LoggerRole'), 'Logger does LoggerRole');
    ok(NullLogger->does('LoggerRole'), 'NullLogger does LoggerRole');

    ok(1, 'FIX: All notifiers share the same interface — swappable');
};

subtest 'After: 新チャネル追加が容易 — SmsNotifier' => sub {
    my $sms = SmsNotifier->new(phone => '090-1234-5678');
    ok($sms->does('Notifier'), 'SmsNotifier does Notifier');

    $sms->send('テスト通知');
    is(scalar $sms->sent->@*, 1, 'SMS sent successfully');
    is($sms->sent->[0]{phone}, '090-1234-5678', 'Phone number correct');

    ok(1, 'FIX: Adding a new channel requires ZERO changes to NotificationService');
};

subtest 'After: 防衛的コードの消滅を確認' => sub {
    open my $fh, '<', './agents/tests/code-detective-null-object-pattern/after/lib.pl'
        or die $!;
    my $source = do { local $/; <$fh> };
    close $fh;

    my @defined_checks = ($source =~ /if \(defined/g);
    is(scalar @defined_checks, 0,
        'FIX: ZERO defined checks in the After code');
};

done_testing;
