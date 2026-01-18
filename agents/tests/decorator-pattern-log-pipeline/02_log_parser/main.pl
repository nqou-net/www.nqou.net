use strict;
use warnings;
use lib '.';
use LogParser;
use Data::Dumper;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
print $fh "127.0.0.1 - - [19/Jan/2026:21:15:38 +0900] \"GET /index.html HTTP/1.1\" 200 1234\n";
close $fh;

my $parser = LogParser->new(filename => 'access.log');

while (defined(my $log = $parser->next_log)) {
    # 構造化されたデータとして扱える！
    print "IP: $log->{ip}, Path: $log->{path}, Status: $log->{status}\n";
}

# Cleanup
unlink 'access.log';
