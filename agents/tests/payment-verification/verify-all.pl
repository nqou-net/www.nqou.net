#!/usr/bin/env perl
# verify-all.pl
# 全記事のコードを検証するスクリプト

use v5.36;
use utf8;
use warnings;
use Cwd qw(getcwd);
use File::Spec;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $base_dir = getcwd();
my @articles = (
    {
        num     => 1,
        dir     => '01',
        name    => '基本的な決済審査',
        script  => 'payment-check-01.pl',
        needs_moo => 0,
    },
    {
        num     => 2,
        dir     => '02',
        name    => '条件追加版',
        script  => 'payment-check-02.pl',
        needs_moo => 0,
    },
    {
        num     => 3,
        dir     => '03',
        name    => 'Chain of Responsibility版',
        script  => 'payment-check-03.pl',
        needs_moo => 1,
    },
);

say "=" x 60;
say "決済審査システム - 全体検証";
say "=" x 60;
say "";

my $total_tests = 0;
my $total_passed = 0;

for my $article (@articles) {
    say "### Article $article->{num}: $article->{name} ###";
    
    my $dir = File::Spec->catdir($base_dir, $article->{dir});
    chdir $dir or die "Cannot chdir to $dir: $!";
    
    # スクリプト実行テスト
    say "  スクリプト実行中...";
    my $env = $article->{needs_moo} 
        ? "PERL5LIB=\$HOME/perl5/lib/perl5:\$PERL5LIB "
        : "";
    
    my $output = `${env}perl -Mwarnings=FATAL $article->{script} 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0 && $output !~ /error/i) {
        say "    ✅ 実行成功";
    } else {
        say "    ❌ 実行失敗";
        say "    出力: $output";
    }
    
    # テスト実行
    say "  テスト実行中...";
    my $prove_output = `${env}prove t/ 2>&1`;
    my $prove_exit = $? >> 8;
    
    if ($prove_exit == 0) {
        # テスト数を抽出
        if ($prove_output =~ /Files=\d+, Tests=(\d+),/) {
            my $tests = $1;
            $total_tests += $tests;
            $total_passed += $tests;
            say "    ✅ テスト成功: $tests/$tests passing";
        } else {
            say "    ✅ テスト成功";
        }
    } else {
        say "    ❌ テスト失敗";
        say $prove_output;
    }
    
    say "";
}

chdir $base_dir;

say "=" x 60;
say "検証完了: $total_passed/$total_tests テスト通過";
say "=" x 60;
