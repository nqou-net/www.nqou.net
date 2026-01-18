use strict;
use warnings;
use lib '.';
use LogReader;

# テスト用のダミーログファイルを用意しておく必要があります
# echo "127.0.0.1 - - [19/Jan/2026:21:15:21 +0900] \"GET /index.html HTTP/1.1\" 200 1234" > access.log

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
print $fh "127.0.0.1 - - [19/Jan/2026:21:15:21 +0900] \"GET /index.html HTTP/1.1\" 200 1234\n";
close $fh;

my $reader = LogReader->new(filename => 'access.log');

# 1行ずつ読み込んで表示
while (defined(my $line = $reader->next_line)) {
    print "Read: $line\n";
}

# Cleanup
unlink 'access.log';
