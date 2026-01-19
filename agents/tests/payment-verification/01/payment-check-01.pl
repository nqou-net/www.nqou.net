#!/usr/bin/env perl
# payment-check-01.pl
# ペルマート決済審査（基本版）
# Perl v5.36+, 外部依存なし

use v5.36;
use utf8;
use warnings;
binmode STDOUT, ':utf8';

sub check_payment ($request) {
    my $amount       = $request->{amount}       // 0;
    my $expiry_year  = $request->{expiry_year}  // 0;
    my $expiry_month = $request->{expiry_month} // 0;

    # 金額上限チェック（10万円以上は拒否）
    if ($amount >= 100_000) {
        return { ok => 0, reason => '金額が上限（10万円）を超えています' };
    }

    # 有効期限チェック
    my ($current_year, $current_month) = (localtime)[5,4];
    $current_year  += 1900;
    $current_month += 1;

    if ($expiry_year < $current_year) {
        return { ok => 0, reason => 'カードの有効期限が切れています' };
    }
    if ($expiry_year == $current_year && $expiry_month < $current_month) {
        return { ok => 0, reason => 'カードの有効期限が切れています' };
    }

    return { ok => 1, amount => $amount };
}

# === 実行例 ===
unless (caller) {
    my @test_cases = (
        { amount => 50_000,  expiry_year => 2028, expiry_month => 12 },  # 正常
        { amount => 50_000,  expiry_year => 2025, expiry_month => 6 },   # 期限切れ
        { amount => 200_000, expiry_year => 2028, expiry_month => 12 },  # 金額オーバー
    );

    for my $i (0 .. $#test_cases) {
        say "=== テスト" . ($i + 1) . " ===";
        my $result = check_payment($test_cases[$i]);

        if ($result->{ok}) {
            say "承認: 決済金額 $result->{amount} 円";
        }
        else {
            say "拒否: $result->{reason}";
        }
        say "";
    }
}

1;
