#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";

# IPFilteredLogParserのテスト
use_ok('IPFilteredLogParser');

my $parser = IPFilteredLogParser->new(
    filename  => $log_file,
    target_ip => '127.0.0.1',
);
isa_ok($parser, 'IPFilteredLogParser');
isa_ok($parser, 'LogParser');

# 127.0.0.1のログのみ取得
my @logs;
while (defined(my $log = $parser->next_log)) {
    push @logs, $log;
}

# サンプルログでは127.0.0.1は5件
is(scalar @logs, 5, 'Found 5 logs from 127.0.0.1');

# 全てのIPが127.0.0.1であること
for my $log (@logs) {
    is($log->{ip}, '127.0.0.1', "IP is 127.0.0.1");
}

done_testing();
