#!/usr/bin/env perl
use v5.36;
use utf8;
use open qw(:std :utf8);
use Test::More;
use lib '../lib';
use lib '../../01/lib';
use lib '../../02/lib';
use MarkdownReader;
use HeadingExtractor;
use TOCParser;
use AnchoredRenderer;

my $sample_file = '../../01/data/sample.md';

subtest 'AnchoredRenderer - アンカーリンク生成' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    my $renderer = AnchoredRenderer->new(root => $parser->root);
    
    isa_ok($renderer, 'AnchoredRenderer');
    
    my $output = $renderer->render;
    
    # リンク形式のチェック
    like($output, qr/\[はじめに\]\(#はじめに\)/, 'はじめにのリンク');
    like($output, qr/\[第1章\]\(#第1章\)/, '第1章のリンク');
    
    diag("=== リンク付き目次 ===");
    diag($output);
};

subtest 'アンカーID生成ルール' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    my $renderer = AnchoredRenderer->new(root => $parser->root);
    
    # _text_to_anchorメソッドのテスト
    is($renderer->_text_to_anchor('Hello World'), '#hello-world', '空白をハイフンに');
    is($renderer->_text_to_anchor('はじめに'), '#はじめに', '日本語は保持');
    is($renderer->_text_to_anchor('第1章'), '#第1章', '数字は保持');
};

done_testing;
