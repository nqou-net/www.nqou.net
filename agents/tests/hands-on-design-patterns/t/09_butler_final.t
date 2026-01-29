#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第9回の完成版をテスト

subtest 'butler_final.pl - 完成版Bot' => sub {
    require 'butler_final.pl';

    my $factory = CommandFactory->new;
    $factory->register(HelloCommand->new)->register(HelpCommand->new)->register(StatusCommand->new)->register(StyleCommand->new)->register(JokeCommand->new);

    my $metrics = MetricsObserver->new;
    my $bot     = ButlerBot->new(factory => $factory, metrics => $metrics);
    $bot->attach($metrics);

    # Friendly style (default)
    like($bot->handle_message('alice', '/hello'), qr/👋/, 'friendly greeting has emoji');

    # Help shows all commands
    like($bot->handle_message('alice', '/help'), qr/\/hello/, 'help lists commands');

    # Change style
    $bot->handle_message('bob', '/style formal');
    like($bot->handle_message('bob', '/hello'), qr/Good day/, 'formal greeting');

    # Metrics tracking
    my $report = $metrics->report;
    ok($report->{hello} >= 2, 'hello command counted');
    ok($report->{help} >= 1,  'help command counted');
};

done_testing;
