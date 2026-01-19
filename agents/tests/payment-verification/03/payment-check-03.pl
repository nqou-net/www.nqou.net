#!/usr/bin/env perl
# payment-check-03.pl
# ペルマート決済審査（Chain of Responsibility版）
# Perl v5.36+, Moo

use v5.36;
use utf8;
use warnings;
use Moo;
binmode STDOUT, ':utf8';

# ===========================================
# 基底クラス: PaymentChecker
# ===========================================
package PaymentChecker {
    use Moo;

    has 'next_handler' => (
        is        => 'rw',
        predicate => 'has_next_handler',
    );

    sub set_next ($self, $handler) {
        $self->next_handler($handler);
        return $handler;
    }

    sub check ($self, $request) {
        return $self->pass_to_next($request);
    }

    sub pass_to_next ($self, $request) {
        if ($self->has_next_handler) {
            return $self->next_handler->check($request);
        }
        return { ok => 1 };
    }
}

# ===========================================
# 金額上限チェッカー
# ===========================================
package LimitChecker {
    use Moo;
    extends 'PaymentChecker';

    has 'limit' => (
        is      => 'ro',
        default => 100_000,
    );

    sub check ($self, $request) {
        my $amount = $request->{amount} // 0;

        if ($amount >= $self->limit) {
            return {
                ok     => 0,
                reason => sprintf('金額が上限（%d円）を超えています', $self->limit),
            };
        }

        return $self->pass_to_next($request);
    }
}

# ===========================================
# 有効期限チェッカー
# ===========================================
package ExpiryChecker {
    use Moo;
    extends 'PaymentChecker';

    sub check ($self, $request) {
        my $expiry_year  = $request->{expiry_year}  // 0;
        my $expiry_month = $request->{expiry_month} // 0;

        my ($current_year, $current_month) = (localtime)[5,4];
        $current_year  += 1900;
        $current_month += 1;

        my $is_expired = $expiry_year < $current_year ||
            ($expiry_year == $current_year && $expiry_month < $current_month);

        if ($is_expired) {
            return {
                ok     => 0,
                reason => 'カードの有効期限が切れています',
            };
        }

        return $self->pass_to_next($request);
    }
}

# ===========================================
# ブラックリストチェッカー
# ===========================================
package BlacklistChecker {
    use Moo;
    extends 'PaymentChecker';

    has 'blacklist' => (
        is      => 'ro',
        default => sub { [] },
    );

    sub check ($self, $request) {
        my $card_number = $request->{card_number} // '';

        for my $blacklisted (@{ $self->blacklist }) {
            if ($card_number eq $blacklisted) {
                return {
                    ok     => 0,
                    reason => 'このカードは使用できません',
                };
            }
        }

        return $self->pass_to_next($request);
    }
}

# ===========================================
# 残高チェッカー
# ===========================================
package BalanceChecker {
    use Moo;
    extends 'PaymentChecker';

    has 'balance_db' => (
        is      => 'ro',
        default => sub { {} },
    );

    sub check ($self, $request) {
        my $card_number = $request->{card_number} // '';
        my $amount      = $request->{amount}      // 0;
        my $balance     = $self->balance_db->{$card_number} // 0;

        if ($balance < $amount) {
            return {
                ok     => 0,
                reason => '利用可能枠が不足しています',
            };
        }

        return $self->pass_to_next($request);
    }
}

# ===========================================
# 不正利用検知チェッカー
# ===========================================
package FraudChecker {
    use Moo;
    extends 'PaymentChecker';

    has 'transaction_log' => (
        is      => 'ro',
        default => sub { {} },
    );

    has 'threshold' => (
        is      => 'ro',
        default => 3,
    );

    sub check ($self, $request) {
        my $card_number  = $request->{card_number} // '';
        my $recent_count = $self->transaction_log->{$card_number} // 0;

        if ($recent_count >= $self->threshold) {
            return {
                ok     => 0,
                reason => '短時間での連続決済を検知しました',
            };
        }

        return $self->pass_to_next($request);
    }
}

# ===========================================
# メイン処理
# ===========================================
package main;

# ダミーデータ（学習用）
my %BALANCE_DB = (
    '4242424242424242' => 100_000,
    '5105105105105100' => 500_000,
);

my %TRANSACTION_LOG = (
    '4111111111111111' => 5,  # 不正利用の疑い
);

# チェッカーを作成
my $limit_checker = LimitChecker->new(limit => 100_000);
my $expiry_checker = ExpiryChecker->new;
my $blacklist_checker = BlacklistChecker->new(
    blacklist => ['4111111111111111', '5500000000000004'],
);
my $balance_checker = BalanceChecker->new(
    balance_db => \%BALANCE_DB,
);
my $fraud_checker = FraudChecker->new(
    transaction_log => \%TRANSACTION_LOG,
    threshold       => 3,
);

# チェーンを構築
$limit_checker
    ->set_next($expiry_checker)
    ->set_next($blacklist_checker)
    ->set_next($balance_checker)
    ->set_next($fraud_checker);

# 審査開始点
our $first_checker = $limit_checker;

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
        {
            name         => '残高不足',
            amount       => 80_000,
            expiry_year  => 2028,
            expiry_month => 12,
            card_number  => '4242424242424242',  # 10万円の枠に対して8万円
        },
    );

    for my $test (@test_cases) {
        say "=== $test->{name} ===";
        my $result = $first_checker->check($test);

        if ($result->{ok}) {
            say "承認: 決済処理に進みます";
        }
        else {
            say "拒否: $result->{reason}";
        }
        say "";
    }
}

1;
