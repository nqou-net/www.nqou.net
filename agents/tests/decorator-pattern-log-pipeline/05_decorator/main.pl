use strict;
use warnings;
use lib '.';
use LogParser;
use IPFilterDecorator;
use Data::Dumper;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:29 +0900] \"GET /index.html HTTP/1.1\" 200 1234\n";
print $fh "192.168.1.1 - - [19/Jan/2026:21:16:32 +0900] \"GET /admin HTTP/1.1\" 403 456\n";
close $fh;

# 1. まず基本のパーサーを作る
my $parser = LogParser->new(filename => 'access.log');

# 2. それをIPフィルターで包む
my $filtered_parser = IPFilterDecorator->new(
    wrapped   => $parser,
    target_ip => '127.0.0.1',
);

# 3. 使う（使い方はLogParserと同じ！）
while (defined(my $log = $filtered_parser->next_log)) {
    print "IP: $log->{ip}\n";
}

# Cleanup
unlink 'access.log';
