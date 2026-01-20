#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';

# 天気情報ツールで覚えるPerl - テスト実行スクリプト

say "╔═══════════════════════════════════════════════════════════════╗";
say "║  天気情報ツールで覚えるPerl - 全5回 コード検証スクリプト      ║";
say "╚═══════════════════════════════════════════════════════════════╝";
say "";

my @tests = (
    {
        round => 1,
        title => '天気情報を表示するクラスを作ろう',
        dir   => '01',
        test  => '01_weather_service.t',
    },
    {
        round => 2,
        title => '異なるAPIを持つサービスを追加する方法',
        dir   => '02',
        test  => '02_interface_problem.t',
    },
    {
        round => 3,
        title => 'インターフェースを変換する橋渡しクラスの実装',
        dir   => '03',
        test  => '03_adapter_pattern.t',
    },
    {
        round => 4,
        title => '複数サービスを統一インターフェースで扱う設計',
        dir   => '04',
        test  => '04_multi_service.t',
    },
    {
        round => 5,
        title => 'これがAdapterパターンだ！',
        dir   => '05',
        test  => '05_adapter_pattern_complete.t',
    },
);

my $total_tests = 0;
my $passed_tests = 0;
my $failed_rounds = 0;

for my $test (@tests) {
    say "【第$test->{round}回】$test->{title}";
    say "─" x 60;
    
    my $cmd = "perl $test->{dir}/t/$test->{test} 2>&1";
    my $output = `$cmd`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0) {
        # テスト数を取得
        if ($output =~ /1\.\.(\d+)/) {
            my $count = $1;
            $total_tests += $count;
            $passed_tests += $count;
            say "✅ PASS ($count テスト)";
        } else {
            say "✅ PASS";
        }
    } else {
        say "❌ FAIL";
        $failed_rounds++;
        # 失敗したテストの詳細を表示
        for my $line (split /\n/, $output) {
            if ($line =~ /^not ok/) {
                say "  $line";
            }
        }
    }
    say "";
}

say "═" x 60;
say "検証結果サマリー";
say "═" x 60;
say "総テスト数: $total_tests";
say "成功: $passed_tests";
say "失敗: " . ($total_tests - $passed_tests);
say "失敗した回: $failed_rounds / " . scalar(@tests);
say "";

if ($failed_rounds == 0) {
    say "🎉 すべてのテストがPASSしました！";
    say "";
    say "Adapterパターンの実装が正しく動作していることを確認しました。";
    say "記事のコードは信頼性が高く、学習教材として優れています。";
} else {
    say "⚠️ 一部のテストが失敗しました。";
    say "詳細は上記のエラーメッセージを確認してください。";
}

say "";
say "─" x 60;
say "検証環境: Perl $^V";
say "検証日時: " . localtime();
say "─" x 60;
