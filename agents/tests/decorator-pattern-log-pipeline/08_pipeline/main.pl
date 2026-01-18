use strict;
use warnings;
use lib '.';
use PipelineBuilder;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
# 127.0.0.1 (Target)
print $fh "127.0.0.1 - - [19/Jan/2026:21:17:20 +0900] \"GET /index.html HTTP/1.1\" 200 100\n";
# 連続404 (Target IP)
for my $i (1..5) {
    print $fh "127.0.0.1 - - [19/Jan/2026:21:17:21 +0900] \"GET /missing$i HTTP/1.1\" 404 100\n";
}
# Non-target IP
print $fh "192.168.1.1 - - [19/Jan/2026:21:17:22 +0900] \"GET /admin HTTP/1.1\" 200 200\n";
close $fh;

# ビルダーを使ってパイプラインを一発構築
my $pipeline = PipelineBuilder->new->build('pipeline.json', 'access.log');

# あとは回すだけ！
while (defined(my $log = $pipeline->next_log)) {
    # 処理はすべてDecoratorたちが勝手にやってくれる
}

# もし集計機能が含まれていれば、レポートを出せるかも？
if ($pipeline->can('report')) {
    $pipeline->report();
}

# Cleanup
unlink 'access.log';
