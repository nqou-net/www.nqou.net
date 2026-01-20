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
use FlatTOCRenderer;

my $sample_file = '../../01/data/sample.md';

subtest 'FlatTOCRenderer基本機能' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $renderer = FlatTOCRenderer->new(headings => $extractor->headings);
    
    isa_ok($renderer, 'FlatTOCRenderer');
    
    my $output = $renderer->render;
    like($output, qr/^- はじめに/, '最初の行はルート見出し');
    like($output, qr/  - 第1章/, '第1章は2スペースインデント');
    like($output, qr/    - セクション1\.1/, 'セクション1.1は4スペースインデント');
};

done_testing;
