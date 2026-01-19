#!/usr/bin/env perl
# payment-check-02.pl
# ペルマート決済審査（条件追加版）
# Perl v5.36+, 外部依存なし
# 
# このコードは「問題のあるコード」の例です。
# 次回の記事で改善方法を学びます。

use v5.36;
use utf8;
use warnings;
binmode STDOUT, ':utf8';

# ブラックリスト（学習用のダミーデータ）
my @BLACKLIST = ('4111111111111111', '5500000000000004');

# 直近の決済履歴（学習用のダミーデータ）
my %RECENT_TRANSACTIONS = (
    '4111111111111111' => 3,
    '4242424242424242' => 1,
);

# 残高情報（学習用のダミーデータ）
my %AVAILABLE_BALANCE = (
    '4242424242424242' => 100_000,
    '5105105105105100' => 500_000,
);

sub check_payment ($request) {
    my $amount       = $request->{amount}       // 0;
    my $expiry_year  = $request->{expiry_year}  // 0;
    my $expiry_month = $request->{expiry_month} // 0;
    my $card_number  = $request->{card_number}  // '';

    # 1. 金額上限チェック
    if ($amount >= 100_000) {
        return { ok => 0, reason => '金額が上限を超えています' };
    }

    # 2. 有効期限チェック
    my ($current_year, $current_month) = (localtime)[5,4];
    $current_year  += 1900;
    $current_month += 1;
    if ($expiry_year < $current_year ||
        ($expiry_year == $current_year && $expiry_month < $current_month)) {
        return { ok => 0, reason => '有効期限が切れています' };
    }

    # 3. ブラックリストチェック
    for my $blacklisted_card (@BLACKLIST) {
        if ($card_number eq $blacklisted_card) {
            return { ok => 0, reason => 'このカードは使用できません' };
        }
    }

    # 4. 残高確認
    my $balance = $AVAILABLE_BALANCE{$card_number} // 0;
    if ($balance < $amount) {
        return { ok => 0, reason => '利用可能枠が不足しています' };
    }

    # 5. 不正利用検知
    my $recent_count = $RECENT_TRANSACTIONS{$card_number} // 0;
    if ($recent_count >= 3) {
        return { ok => 0, reason => '短時間での連続決済を検知しました' };
    }

    return { ok => 1, amount => $amount };
}

# === 実行例 ===
unless (caller) {
    my @test_cases = (
        {
            name         => '正常な決済',
            amount       => 50_000,
            expiry_year  => 2028,
            expiry_month => 12,
            card_number  => '5105105105105100',
        },
        {
            name         => '金額オーバー',
            amount       => 200_000,
            expiry_year  => 2028,
            expiry_month => 12,
            card_number  => '5105105105105100',
        },
        {
            name         => '期限切れ',
            amount       => 50_000,
            expiry_year  => 2025,
            expiry_month => 6,
            card_number  => '5105105105105100',
        },
        {
            name         => 'ブラックリスト',
            amount       => 50_000,
            expiry_year  => 2028,
            expiry_month => 12,
            card_number  => '4111111111111111',
        },
    );

    for my $test (@test_cases) {
        say "=== $test->{name} ===";
        my $result = check_payment($test);

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
