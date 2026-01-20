#!/usr/bin/env perl
use v5.36;
use Test2::V0;
use utf8;
use Encode qw(decode);

# Capture output by running the script
my $output = decode('UTF-8', qx{perl bookshelf.pl 2>&1});
chomp $output if $output;
$output .= "\n";  # Add back the final newline

# Capture warnings separately
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    do './bookshelf.pl';
}

# Expected output
my $expected = <<'EXPECTED';
=== 方法1: books配列に直接アクセス(問題あり) ===
すぐわかるPerl / 深沢千尋
初めてのPerl / Randal L. Schwartz
プログラミングPerl / Larry Wall

=== 方法2: メソッド経由でアクセス(改善版) ===
すぐわかるPerl / 深沢千尋
初めてのPerl / Randal L. Schwartz
プログラミングPerl / Larry Wall
EXPECTED

is($output, $expected, 'Output matches expected');
is(\@warnings, [], 'No warnings during execution');

done_testing;
