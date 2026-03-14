#!/usr/bin/env perl
use v5.34;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Capture::Tiny qw(capture_stdout capture_stderr);

subtest 'コード例1 - 問題版' => sub {
    require 'example1_problem.pl';

    my $processor = OrderProcessor->new;
    my $order_fail = { amount => 1000, should_fail => 1 };

    my ($stdout, $stderr) = capture_stdout {
        eval { $processor->process_order($order_fail) };
    };

    like $@, qr/Order save failed/, "Errs on save_order";
    like $stdout, qr/\[API\] Charged 1000/, "API was charged";
    unlike $stdout, qr/\[API\] Refunded/, "API was NEVER refunded (The problem!)";
};

subtest 'コード例2 - 改善版' => sub {
    require 'example1_solution.pl';

    my $processor = OrderProcessorSmart->new;
    my $order_fail = { amount => 1000, should_fail => 1 };

    my ($stdout, $stderr) = capture_stdout {
        eval { $processor->process_order($order_fail) };
    };

    like $@, qr/Order processing failed/, "Errs on processing";
    like $stdout, qr/\[API\] Charged 1000/, "API was charged";
    like $stdout, qr/\[API\] Refunded/, "API WAS refunded due to Command pattern's undo!";
};

done_testing;
