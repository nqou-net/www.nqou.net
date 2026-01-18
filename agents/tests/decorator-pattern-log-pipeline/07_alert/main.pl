use strict;
use warnings;
use lib '.';
use LogParser;
use StatsAggregatorDecorator;
use AlertDecorator;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
# 5回連続404を発生させる
for my $i (1..5) {
    print $fh "127.0.0.1 - - [19/Jan/2026:21:17:03 +0900] \"GET /missing$i HTTP/1.1\" 404 100\n";
}
# 正常系
print $fh "127.0.0.1 - - [19/Jan/2026:21:17:04 +0900] \"GET /index.html HTTP/1.1\" 200 200\n";
close $fh;

# 1. 基本
my $parser = LogParser->new(filename => 'access.log');

# 2. アラート（閾値5回）
my $alert = AlertDecorator->new(
    wrapped   => $parser,
    threshold => 5,
);

# 3. 統計
my $stats = StatsAggregatorDecorator->new(
    wrapped => $alert,
);

# 実行
while (defined(my $log = $stats->next_log)) {
    # ログが流れるたびに、裏でアラート判定と統計集計が行われる
}

$stats->report();

# Cleanup
unlink 'access.log';
