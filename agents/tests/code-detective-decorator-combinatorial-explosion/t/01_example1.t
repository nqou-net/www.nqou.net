#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Beforeコード（問題版）を読み込み
require 'example1_problem.pl';

subtest 'Problem: Combinatorial Explosion of Subclasses' => sub {

    subtest 'Basic notifiers work' => sub {
        my $email = EmailNotifier->new(recipient => 'user@example.com');
        like($email->send("Hello"), qr/\[Email to user\@example\.com\] Hello/, 'EmailNotifier sends correctly');

        my $slack = SlackNotifier->new(recipient => '#general');
        like($slack->send("Hello"), qr/\[Slack to #general\] Hello/, 'SlackNotifier sends correctly');
    };

    subtest 'Email + Retry subclass' => sub {
        my $notifier = EmailRetryNotifier->new(recipient => 'user@example.com', max_retries => 2);
        my $result = $notifier->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        like($result, qr/retried up to 2 times/, 'contains retry info');
    };

    subtest 'Email + Log subclass' => sub {
        my $notifier = EmailLogNotifier->new(recipient => 'user@example.com');
        my $result = $notifier->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        is(scalar @{$notifier->log}, 1, 'log has one entry');
        like($notifier->log->[0], qr/^LOG:/, 'log entry starts with LOG:');
    };

    subtest 'Email + Retry + Log subclass (copy-paste hell)' => sub {
        my $notifier = EmailRetryLogNotifier->new(recipient => 'user@example.com', max_retries => 2);
        my $result = $notifier->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        like($result, qr/retried up to 2 times/, 'contains retry info');
        is(scalar @{$notifier->log}, 1, 'log has one entry');
    };

    subtest 'Slack + Retry subclass (duplicated retry logic)' => sub {
        my $notifier = SlackRetryNotifier->new(recipient => '#alerts', max_retries => 2);
        my $result = $notifier->send("Alert");
        like($result, qr/\[Slack to #alerts\] Alert/, 'contains slack output');
        like($result, qr/retried up to 2 times/, 'contains retry info');
    };

    subtest 'Slack + Retry + Log subclass (more duplication)' => sub {
        my $notifier = SlackRetryLogNotifier->new(recipient => '#alerts', max_retries => 2);
        my $result = $notifier->send("Alert");
        like($result, qr/\[Slack to #alerts\] Alert/, 'contains slack output');
        like($result, qr/retried up to 2 times/, 'contains retry info');
        is(scalar @{$notifier->log}, 1, 'log has one entry');
    };

    subtest 'PROBLEM: Adding SMS would require 4+ more subclasses' => sub {
        # SmsNotifier, SmsRetryNotifier, SmsLogNotifier, SmsRetryLogNotifier...
        # We can't even test this without creating them!
        pass('No SmsNotifier exists - would require explosion of new classes');
    };
};

# Afterコード（改善版）を読み込み
require 'example1_solution.pl';

subtest 'Solution: Decorator Pattern' => sub {

    subtest 'Basic senders work' => sub {
        my $email = EmailSender->new(recipient => 'user@example.com');
        like($email->send("Hello"), qr/\[Email to user\@example\.com\] Hello/, 'EmailSender sends correctly');

        my $slack = SlackSender->new(recipient => '#general');
        like($slack->send("Hello"), qr/\[Slack to #general\] Hello/, 'SlackSender sends correctly');

        my $sms = SmsSender->new(recipient => '090-1234-5678');
        like($sms->send("Hello"), qr/\[SMS to 090-1234-5678\] Hello/, 'SmsSender sends correctly');
    };

    subtest 'RetryDecorator wraps any notifier' => sub {
        my $email_retry = RetryDecorator->new(
            notifier    => EmailSender->new(recipient => 'user@example.com'),
            max_retries => 2,
        );
        my $result = $email_retry->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        like($result, qr/retried up to 2 times/, 'contains retry info');

        # Same decorator works for Slack!
        my $slack_retry = RetryDecorator->new(
            notifier    => SlackSender->new(recipient => '#alerts'),
            max_retries => 3,
        );
        my $slack_result = $slack_retry->send("Alert");
        like($slack_result, qr/\[Slack to #alerts\] Alert/, 'contains slack output');
        like($slack_result, qr/retried up to 3 times/, 'contains retry info');
    };

    subtest 'LogDecorator wraps any notifier' => sub {
        my $email_log = LogDecorator->new(
            notifier => EmailSender->new(recipient => 'user@example.com'),
        );
        my $result = $email_log->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        is(scalar @{$email_log->log}, 1, 'log has one entry');
        like($email_log->log->[0], qr/^LOG:/, 'log entry starts with LOG:');
    };

    subtest 'FilterDecorator blocks matching messages' => sub {
        my $filtered = FilterDecorator->new(
            notifier    => EmailSender->new(recipient => 'user@example.com'),
            filter_word => 'spam',
        );
        my $blocked = $filtered->send("This is spam content");
        like($blocked, qr/\[FILTERED\]/, 'spam message is filtered');

        my $passed = $filtered->send("Important alert");
        like($passed, qr/\[Email to user\@example\.com\]/, 'non-spam message passes through');
    };

    subtest 'Decorators can be stacked freely' => sub {
        # Email + Retry + Log (same as the problematic EmailRetryLogNotifier)
        my $stacked = LogDecorator->new(
            notifier => RetryDecorator->new(
                notifier    => EmailSender->new(recipient => 'user@example.com'),
                max_retries => 2,
            ),
        );
        my $result = $stacked->send("Alert");
        like($result, qr/\[Email to user\@example\.com\] Alert/, 'contains email output');
        like($result, qr/retried up to 2 times/, 'contains retry info from inner decorator');
        is(scalar @{$stacked->log}, 1, 'log captured the result');
    };

    subtest 'Adding SMS requires only ONE new class' => sub {
        # SMS + Retry + Log + Filter — no new subclasses needed!
        my $sms_full = LogDecorator->new(
            notifier => FilterDecorator->new(
                notifier    => RetryDecorator->new(
                    notifier => SmsSender->new(recipient => '090-1234-5678'),
                ),
                filter_word => 'test',
            ),
        );

        my $result = $sms_full->send("Production alert");
        like($result, qr/\[SMS to 090-1234-5678\]/, 'SMS works with all decorators');
        like($result, qr/retried up to 3 times/, 'retry decorator applied');
        is(scalar @{$sms_full->log}, 1, 'log decorator captured result');

        my $filtered = $sms_full->send("test message");
        like($filtered, qr/\[FILTERED\]/, 'filter decorator works with SMS too');
    };

    subtest 'Recipient is delegated from inner notifier' => sub {
        my $decorated = RetryDecorator->new(
            notifier => EmailSender->new(recipient => 'boss@example.com'),
        );
        is($decorated->recipient, 'boss@example.com', 'recipient delegated from inner notifier');

        my $double = LogDecorator->new(
            notifier => RetryDecorator->new(
                notifier => SlackSender->new(recipient => '#critical'),
            ),
        );
        is($double->recipient, '#critical', 'recipient delegated through multiple decorators');
    };
};

done_testing;
