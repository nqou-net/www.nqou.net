#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;

subtest '01_problem.pl runs successfully' => sub {
    my $script = "$FindBin::Bin/../lib/01_problem.pl";
    my $output = `perl $script`;
    ok($? == 0, 'Script exited successfully');
    like($output, qr/--- Before/, 'Output contains expected header');
    like($output, qr/\+ root/, 'Output contains root folder');
    like($output, qr/- vi/, 'Output contains file vi');
    
    # 構造のチェック
    like($output, qr/\s{2}\+ bin/, 'Indentation logic works');
    like($output, qr/\s{4}- vi/, 'Nested file indentation works');
};

subtest '02_solution.pl runs successfully' => sub {
    my $script = "$FindBin::Bin/../lib/02_solution.pl";
    my $output = `perl $script`;
    ok($? == 0, 'Script exited successfully');
    like($output, qr/--- After/, 'Output contains expected header');
    like($output, qr/\+ root/, 'Output contains root folder');
    like($output, qr/- vi/, 'Output contains file vi');
    
    # 構造のチェック
    like($output, qr/\s{2}\+ bin/, 'Indentation logic works');
    like($output, qr/\s{4}- vi/, 'Nested file indentation works');
};

done_testing;
