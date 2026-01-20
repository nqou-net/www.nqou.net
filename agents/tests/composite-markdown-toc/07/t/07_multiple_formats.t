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

subtest '複数フォーマット出力 - Markdown' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    my $output = $parser->render('markdown');
    
    like($output, qr/^- /, 'Markdownリストマーカー');
    unlike($output, qr/</, 'HTMLタグを含まない');
};

subtest '複数フォーマット出力 - HTML' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    my $output = $parser->render('html');
    
    like($output, qr/<ul>/, 'ulタグを含む');
    like($output, qr/<\/ul>/, '閉じulタグを含む');
    like($output, qr/<li>/, 'liタグを含む');
};

subtest '複数フォーマット出力 - JSON' => sub {
    my $reader = MarkdownReader->new(filepath => $sample_file);
    my $extractor = HeadingExtractor->new(lines => $reader->lines);
    my $parser = TOCParser->new(headings => $extractor->headings);
    
    my $output = $parser->render('json');
    
    like($output, qr/\[/, 'JSON配列開始');
    like($output, qr/"text"/, 'textフィールド');
    like($output, qr/"children"/, 'childrenフィールド');
};

done_testing;
