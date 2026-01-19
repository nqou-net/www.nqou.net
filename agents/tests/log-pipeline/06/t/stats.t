#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";

use_ok('LogParser');
use_ok('StatsAggregatorDecorator');

my $parser = LogParser->new(filename => $log_file);
my $stats = StatsAggregatorDecorator->new(wrapped => $parser);

# 全ログ処理
while (defined(my $log = $stats->next_log)) {
    # パススルー
}

# 統計確認
my $s = $stats->stats;
is($s->{total_requests}, 7, 'Total 7 requests');
is($s->{status_count}->{200}, 4, '4 x 200 OK');
is($s->{status_count}->{404}, 3, '3 x 404 Not Found');

# 合計サイズ = 1234 + 5678 + 123 + 890 + 456 + 789 + 111 = 9281
is($s->{total_size}, 9281, 'Total size correct');

done_testing();
