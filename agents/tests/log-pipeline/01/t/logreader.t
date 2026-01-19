#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use lib '../data';
use FindBin qw($Bin);

# テスト用ログファイル
my $log_file = "$Bin/../data/access.log";

# LogReaderのテスト
use_ok('LogReader');

my $reader = LogReader->new(filename => $log_file);
isa_ok($reader, 'LogReader');

# 1行目読み込み
my $line1 = $reader->next_line;
like($line1, qr/127\.0\.0\.1/, '1st line contains IP 127.0.0.1');
like($line1, qr/GET \/index\.html/, '1st line contains GET /index.html');

# 2行目読み込み
my $line2 = $reader->next_line;
like($line2, qr/192\.168\.1\.1/, '2nd line contains IP 192.168.1.1');

# 全行読み込み
my $count = 2;
while (defined(my $line = $reader->next_line)) {
    $count++;
}
is($count, 7, 'Total 7 lines in log file');

# 読み終わり後はundef
my $eof = $reader->next_line;
is($eof, undef, 'Returns undef after EOF');

done_testing();
