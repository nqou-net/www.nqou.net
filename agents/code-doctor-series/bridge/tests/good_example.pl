#!/usr/bin/env perl
use v5.36;
use lib 'lib';

use Good::Sender::Email;
use Good::Sender::SMS;
use Good::UrgentNotifier;
use Good::NormalNotifier;

# Implementations
my $email = Good::Sender::Email->new;
my $sms   = Good::Sender::SMS->new;

# Abstractions (Bridge with Implementation)
my $urgent_email = Good::UrgentNotifier->new(sender => $email);
my $urgent_sms   = Good::UrgentNotifier->new(sender => $sms);
my $normal_email = Good::NormalNotifier->new(sender => $email);

# Execution
$urgent_email->notify("Server Down");
$urgent_sms->notify("Server Down");
$normal_email->notify("Weekly Report");

# 新しい送信手段 (Slack) が増えても、Good::Notifier系は修正不要
# 新しい優先度 (Critical) が増えても、Good::Sender系は修正不要
