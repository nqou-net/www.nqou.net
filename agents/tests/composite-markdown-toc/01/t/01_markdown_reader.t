#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib '../lib';
use MarkdownReader;

# テスト用ファイルのパス
my $sample_file = '../data/sample.md';

# MarkdownReaderのテスト
subtest 'MarkdownReader基本機能' => sub {
    ok(-f $sample_file, 'サンプルファイルが存在する');
    
    my $reader = MarkdownReader->new(filepath => $sample_file);
    isa_ok($reader, 'MarkdownReader');
    
    is($reader->filepath, $sample_file, 'filepathが正しく設定される');
    
    my $lines = $reader->lines;
    is(ref($lines), 'ARRAY', 'linesは配列リファレンス');
    ok($reader->line_count > 0, '行数が0より大きい');
    
    # 最初の行が見出しであることを確認
    like($lines->[0], qr/^#/, '最初の行は見出し');
};

done_testing;
