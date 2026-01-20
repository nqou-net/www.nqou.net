#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib '../lib';
use LeafHeading;
use SectionHeading;

subtest 'Compositeパターン - 手動ツリー構築' => sub {
    my $root = SectionHeading->new(
        level => 1,
        text  => 'はじめに',
    );
    
    my $chapter1 = SectionHeading->new(
        level => 2,
        text  => '第1章',
    );
    
    my $section1_1 = LeafHeading->new(
        level => 3,
        text  => 'セクション1.1',
    );
    
    my $chapter2 = LeafHeading->new(
        level => 2,
        text  => '第2章',
    );
    
    $chapter1->add_child($section1_1);
    $root->add_child($chapter1);
    $root->add_child($chapter2);
    
    my $output = $root->render;
    
    like($output, qr/^- はじめに/, 'ルートから始まる');
    like($output, qr/  - 第1章/, '第1章がインデント');
    like($output, qr/    - セクション1\.1/, 'セクションがさらにインデント');
    like($output, qr/  - 第2章/, '第2章もインデント');
    
    diag("=== Markdown出力 ===");
    diag($output);
};

subtest 'Compositeパターン - HTML出力' => sub {
    my $root = SectionHeading->new(
        level => 1,
        text  => 'はじめに',
    );
    
    my $chapter1 = LeafHeading->new(
        level => 2,
        text  => '第1章',
    );
    
    $root->add_child($chapter1);
    
    my $output = $root->render(0, 'html');
    
    like($output, qr/<li>はじめに/, 'liタグを含む');
    like($output, qr/<ul>/, 'ulタグを含む');
    
    diag("=== HTML出力 ===");
    diag($output);
};

done_testing;
