#!/usr/bin/env perl
use v5.34;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

my $lib_dir       = "$FindBin::Bin/../lib";
my $before_script = File::Spec->catfile($lib_dir, 'before.pl');
my $after_script  = File::Spec->catfile($lib_dir, 'after.pl');

subtest 'Before Script' => sub {
    my $output = `perl -I$lib_dir "$before_script" 2>&1`;
    ok($? == 0, 'Script executed successfully');
    like($output, qr/直接接続できません/, 'Output contains expected failure message');
};

subtest 'After Script' => sub {
    my $output = `perl -I$lib_dir "$after_script" 2>&1`;
    ok($? == 0, 'Script executed successfully');
    like($output, qr/ヒーローはジャンプした！/, 'Output contains success action');
    like($output, qr/接続成功/,         'Output contains success message');
};

done_testing;
