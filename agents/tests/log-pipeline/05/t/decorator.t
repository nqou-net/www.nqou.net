#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";

# Decorator版テスト
use_ok('LogProcessor');
use_ok('LogParser');
use_ok('LogDecorator');
use_ok('IPFilterDecorator');
use_ok('StatusFilterDecorator');

# 基本のパーサー
my $parser = LogParser->new(filename => $log_file);
ok($parser->does('LogProcessor'), 'LogParser does LogProcessor');

# IPFilterDecorator適用
my $ip_filter = IPFilterDecorator->new(
    wrapped   => $parser,
    target_ip => '127.0.0.1',
);
isa_ok($ip_filter, 'LogDecorator');
ok($ip_filter->does('LogProcessor'), 'IPFilterDecorator does LogProcessor');

# 127.0.0.1のログのみ取得
my @logs;
while (defined(my $log = $ip_filter->next_log)) {
    push @logs, $log;
}
is(scalar @logs, 5, 'Found 5 logs from 127.0.0.1 via Decorator');

# 新しいパーサーで複合フィルタ（IP + 404）
my $parser2 = LogParser->new(filename => $log_file);
my $status_filter = StatusFilterDecorator->new(
    target_status => '404',
    wrapped       => IPFilterDecorator->new(
        target_ip => '127.0.0.1',
        wrapped   => $parser2,
    ),
);

my @not_found;
while (defined(my $log = $status_filter->next_log)) {
    push @not_found, $log;
}
is(scalar @not_found, 3, 'Found 3 404 errors from 127.0.0.1');

done_testing();
