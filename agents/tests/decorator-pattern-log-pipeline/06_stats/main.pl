use strict;
use warnings;
use lib '.';
use LogParser;
use IPFilterDecorator;
use StatsAggregatorDecorator;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:46 +0900] \"GET /index.html HTTP/1.1\" 200 100\n";
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:47 +0900] \"POST /login HTTP/1.1\" 200 200\n";
print $fh "192.168.1.1 - - [19/Jan/2026:21:16:48 +0900] \"GET /admin HTTP/1.1\" 403 50\n";
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:49 +0900] \"GET /missing HTTP/1.1\" 404 150\n";
close $fh;

# 1. 基本のパーサー
my $parser = LogParser->new(filename => 'access.log');

# 2. IPフィルター
my $filter = IPFilterDecorator->new(
    wrapped   => $parser,
    target_ip => '127.0.0.1',
);

# 3. 統計集計（フィルターの後ろに配置！）
my $stats = StatsAggregatorDecorator->new(
    wrapped => $filter,
);

# 処理実行
while (defined(my $log = $stats->next_log)) {
    # 処理中は特に何も表示しなくてもOK
}

# 最後にレポート出力
$stats->report();

# Cleanup
unlink 'access.log';
