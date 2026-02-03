#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Devel::Size qw(total_size);

subtest '01_problem.pl - 症状の確認' => sub {
    # 外部スクリプトとして実行し、出力を確認
    my $output = `perl $FindBin::Bin/../lib/01_problem.pl`;
    like($output, qr/インスタンス増殖症/, 'タイトルが表示されている');
    like($output, qr/森の生成が完了しました/, '実行が完了した');
};

subtest '02_solution.pl - 改善の確認' => sub {
    my $output = `perl $FindBin::Bin/../lib/02_solution.pl`;
    like($output, qr/Flyweightパターンによるメモリ最適化/, 'タイトルが表示されている');
    like($output, qr/共有モデルの数: 1/, 'モデルが共有されている');
    like($output, qr/森の生成が完了しました/, '実行が完了した');
};

# メモリ削減効果の比較（簡易検証）
subtest 'メモリ削減効果の比較' => sub {
    my $out1 = `perl $FindBin::Bin/../lib/01_problem.pl`;
    my $out2 = `perl $FindBin::Bin/../lib/02_solution.pl`;
    
    my ($size1) = $out1 =~ /(\d+) 本の合計推定サイズ: (\d+)/;
    my ($size2) = $out2 =~ /(\d+) 本の合計推定サイズ: (\d+)/;
    
    my $mem1 = (split /: /, (grep { /合計推定サイズ/ } split /\n/, $out1)[0])[1];
    my $mem2 = (split /: /, (grep { /合計推定サイズ/ } split /\n/, $out2)[0])[1];
    
    $mem1 =~ s/ bytes//;
    $mem2 =~ s/ bytes//;

    ok($mem2 < $mem1, "Flyweight導入によりメモリ使用量が削減された ($mem1 -> $mem2)");
    my $ratio = ($mem1 - $mem2) / $mem1 * 100;
    note(sprintf("削減率: %.2f%%", $ratio));
};

done_testing;
