use strict;
use warnings;
use lib '.';
use IPFilteredLogParser;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
print $fh "127.0.0.1 - - [19/Jan/2026:21:15:55 +0900] \"GET /index.html HTTP/1.1\" 200 1234\n";
print $fh "192.168.1.1 - - [19/Jan/2026:21:16:00 +0900] \"GET /admin HTTP/1.1\" 403 456\n";
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:05 +0900] \"POST /login HTTP/1.1\" 200 789\n";
close $fh;

# 127.0.0.1 のログだけを抽出したい
my $parser = IPFilteredLogParser->new(
    filename  => 'access.log',
    target_ip => '127.0.0.1',
);

while (defined(my $log = $parser->next_log)) {
    print "Found target access: Path: $log->{path}\n";
}

# Cleanup
unlink 'access.log';
