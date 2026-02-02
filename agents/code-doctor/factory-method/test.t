#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use File::Spec;

# スクリプトのパス
my $dir           = $FindBin::Bin;
my $before_script = File::Spec->catfile($dir, 'ReportGenerator_Before.pl');
my $after_script  = File::Spec->catfile($dir, 'ReportGenerator_After.pl');

# Beforeを実行
my $before_out = qx{perl "$before_script"};
ok($? == 0, "Before script executed successfully");

# Afterを実行
my $after_out = qx{perl "$after_script"};
ok($? == 0, "After script executed successfully");

# 出力を比較
is($before_out, $after_out, "Output matches between Before and After implementation");

# 詳細な内容確認
like($before_out, qr/CSV Report: Alice,Bob,Charlie/,            "CSV output correctness");
like($before_out, qr/JSON Report: \["Alice","Bob","Charlie"\]/, "JSON output correctness");
like($before_out, qr/<item>Alice<\/item>/,                      "XML output correctness");

done_testing;
