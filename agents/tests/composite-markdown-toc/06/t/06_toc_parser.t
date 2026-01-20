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

my $sample_file = '../../01/data/sample.md';

subtest 'TOCParser - 自動ツリー構築' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    isa_ok($parser, 'TOCParser');
    
    my $output = $parser->render;
    
    like($output, qr/^- はじめに/, 'ルートから始まる');
    like($output, qr/  - 第1章/, '第1章がインデント');
    like($output, qr/    - セクション1\.1/, 'セクションがさらにインデント');
    
    diag("=== Markdown出力 ===");
    diag($output);
};

subtest 'TOCParser - HTML出力' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    my $output = $parser->render('html');
    
    like($output, qr/^<ul>/, 'ulタグから始まる');
    like($output, qr/<li>はじめに/, 'liタグを含む');
    
    diag("=== HTML出力 ===");
    diag($output);
};

subtest 'TOCParser - JSON出力' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    my $output = $parser->render('json');
    
    like($output, qr/"text"/, 'textフィールドを含む');
    like($output, qr/"level"/, 'levelフィールドを含む');
    
    diag("=== JSON出力（冒頭のみ）===");
    diag(substr($output, 0, 200) . "...");
};

done_testing;
