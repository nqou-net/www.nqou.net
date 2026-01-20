#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib '../lib';
use lib '../../01/lib';
use lib '../../02/lib';
use MarkdownReader;
use HeadingExtractor;
use HierarchicalTOCRenderer;

my $sample_file = '../../01/data/sample.md';

subtest 'HierarchicalTOCRenderer - 基本ケース' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $renderer = HierarchicalTOCRenderer->new(headings => $extractor->headings);
    
    my $output = $renderer->render;
    
    # 基本的なHTMLタグが含まれることを確認
    like($output, qr/<ul>/, 'ulタグを含む');
    like($output, qr/<li>/, 'liタグを含む');
    
    diag("=== 基本ケースの出力 ===");
    diag($output);
};

subtest 'HierarchicalTOCRenderer - レベルスキップで破綻' => sub {
    # H1→H3のような飛び級ケース
    my @skip_headings = (
        { level => 1, text => 'はじめに' },
        { level => 3, text => 'いきなりH3' },
        { level => 2, text => '第1章' },
    );
    
    my $renderer = HierarchicalTOCRenderer->new(headings => \@skip_headings);
    my $output = $renderer->render;
    
    # 出力を確認（構造が壊れていることを確認）
    diag("=== レベルスキップの問題出力 ===");
    diag($output);
    
    # <ul>が連続してしまう問題を確認
    my $consecutive_ul = ($output =~ /<ul>\n<ul>/);
    ok($consecutive_ul, '連続した<ul>が存在する（構造の破綻）');
};

done_testing;
