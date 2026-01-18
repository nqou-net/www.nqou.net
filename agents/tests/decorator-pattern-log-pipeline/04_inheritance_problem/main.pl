use strict;
use warnings;
use lib '.';
use IPAndStatusFilteredLogParser;

# ダミーログ作成
open my $fh, '>', 'access.log' or die $!;
# IP一致, Status一致 (Target)
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:12 +0900] \"GET /missing HTTP/1.1\" 404 123\n";
# IP不一致, Status一致
print $fh "192.168.1.1 - - [19/Jan/2026:21:16:15 +0900] \"GET /missing HTTP/1.1\" 404 123\n";
# IP一致, Status不一致
print $fh "127.0.0.1 - - [19/Jan/2026:21:16:18 +0900] \"GET /exists HTTP/1.1\" 200 123\n";
close $fh;

my $parser = IPAndStatusFilteredLogParser->new(
    filename      => 'access.log',
    target_ip     => '127.0.0.1',
    target_status => '404',
);

while (defined(my $log = $parser->next_log)) {
    print "Found target access: Path: $log->{path}, Status: $log->{status}\n";
}

# Cleanup
unlink 'access.log';
