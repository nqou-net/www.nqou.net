#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";

# LogParserのテスト
use_ok('LogParser');

my $parser = LogParser->new(filename => $log_file);
isa_ok($parser, 'LogParser');
isa_ok($parser, 'LogReader');

# 1行目パース
my $log1 = $parser->next_log;
is($log1->{ip}, '127.0.0.1', 'Parsed IP');
is($log1->{method}, 'GET', 'Parsed method');
is($log1->{path}, '/index.html', 'Parsed path');
is($log1->{status}, '200', 'Parsed status');
is($log1->{size}, '1234', 'Parsed size');

# 全ログ読み込み
my $count = 1;
while (defined(my $log = $parser->next_log)) {
    $count++;
}
is($count, 7, 'Total 7 log entries');

done_testing();
