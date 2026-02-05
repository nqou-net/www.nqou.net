#!/usr/bin/env perl
use v5.36;
use lib 'lib';

use Bad::Notifier::Urgent::Email;
use Bad::Notifier::Urgent::SMS;
use Bad::Notifier::Normal::Email;

# 組み合わせごとに異なるクラスが必要
my $urgent_email = Bad::Notifier::Urgent::Email->new();
$urgent_email->send("Server Down");

my $urgent_sms = Bad::Notifier::Urgent::SMS->new();
$urgent_sms->send("Server Down");

my $normal_email = Bad::Notifier::Normal::Email->new();
$normal_email->send("Weekly Report");

# もし "Slack" を追加したら...？
# Bad::Notifier::Urgent::Slack
# Bad::Notifier::Normal::Slack
# ... クラスが倍増していく
