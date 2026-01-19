#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use FindBin qw($Bin);

my $log_file = "$Bin/../data/access.log";
my $config_file = "$Bin/../data/pipeline.json";

use_ok('PipelineBuilder');

# ビルダーでパイプライン構築
my $builder = PipelineBuilder->new;
my $pipeline = $builder->build($config_file, $log_file);

# パイプラインはLogProcessorとして動作
ok($pipeline->does('LogProcessor'), 'Pipeline does LogProcessor');

# 全ログ処理
my @logs;
while (defined(my $log = $pipeline->next_log)) {
    push @logs, $log;
}

# IPフィルタリング + StatsAggregator
is(scalar @logs, 5, 'Found 5 logs from 127.0.0.1');

# 統計確認
if ($pipeline->can('stats')) {
    my $s = $pipeline->stats;
    is($s->{total_requests}, 5, 'Stats: 5 requests from 127.0.0.1');
}

done_testing();
