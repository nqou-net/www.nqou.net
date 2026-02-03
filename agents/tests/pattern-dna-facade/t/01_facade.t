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
    like($output, qr/\[照明\] 消灯しました/, 'Lighting turned off');
    like($output, qr/面倒くさい手順でした/,    'Contains complexity complaint');
};

subtest 'After Script' => sub {
    my $output = `perl -I$lib_dir "$after_script" 2>&1`;
    ok($? == 0, 'Script executed successfully');
    like($output, qr/Facade: 外出シーケンス開始/, 'Facade sequence start');
    like($output, qr/Facade: 外出準備完了/,    'Facade sequence end');
    like($output, qr/\[照明\] 消灯しました/,     'Subsystem still works');
};

done_testing;
