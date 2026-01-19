#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";

use_ok('LogParser');
use_ok('AlertDecorator');

# 閾値2でテスト（連続2回で警告）
my $parser = LogParser->new(filename => $log_file);
my $alert = AlertDecorator->new(
    wrapped   => $parser,
    threshold => 2,
);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, shift };

# 全ログ処理
while (defined(my $log = $alert->next_log)) {
    # 処理
}

# access.logには連続404が2つあるので、閾値2だと警告発生
ok(@warnings > 0, 'Alert triggered for consecutive 404s');
like($warnings[0], qr/ALERT.*404/, 'Warning message contains ALERT and 404');

done_testing();
