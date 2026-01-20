#!/usr/bin/env perl
use v5.36;
use utf8;
use open qw(:std :utf8);
use Test::More;
use lib '../lib';
use lib '../../01/lib';
use MarkdownReader;
use HeadingExtractor;

my $sample_file = '../../01/data/sample.md';

subtest 'HeadingExtractor基本機能' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    
    isa_ok($extractor, 'HeadingExtractor');
    
    my $headings = $extractor->headings;
    is(ref($headings), 'ARRAY', 'headingsは配列リファレンス');
    is($extractor->heading_count, 4, '見出し数は4');
    
    # 最初の見出しはレベル1
    is($headings->[0]{level}, 1, '最初の見出しはレベル1');
    is($headings->[0]{text}, 'はじめに', '最初の見出しテキスト');
    
    # レベル2とレベル3の確認
    is($headings->[1]{level}, 2, '第1章はレベル2');
    is($headings->[2]{level}, 3, 'セクション1.1はレベル3');
};

done_testing;
