use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-double-dispatch/before/lib.pl' or die $@ || $!;

my $proc = PaymentProcessor->new;

subtest 'Before: 通常注文 × クレジットカード' => sub {
    my $result = $proc->process(
        NormalOrder->new(total => 5000),
        CreditCard->new,
    );
    is($result->{method}, 'credit',  '決済方法はcredit');
    is($result->{amount}, 5000,      '金額は5000');
    is($result->{status}, 'charged', 'ステータスはcharged');
};

subtest 'Before: 通常注文 × 銀行振込' => sub {
    my $result = $proc->process(
        NormalOrder->new(total => 3000),
        BankTransfer->new,
    );
    is($result->{method},   'bank',    '決済方法はbank');
    is($result->{amount},   3000,      '金額は3000');
    is($result->{status},   'pending', 'ステータスはpending');
    is($result->{due_days}, 7,         '支払期限は7日');
};

subtest 'Before: 通常注文 × コンビニ払い' => sub {
    my $result = $proc->process(
        NormalOrder->new(total => 2000),
        ConvenienceStore->new,
    );
    is($result->{method},     'convenience', '決済方法はconvenience');
    is($result->{amount},     2000,          '金額は2000');
    is($result->{status},     'awaiting',    'ステータスはawaiting');
    is($result->{expires_in}, 3,             '有効期限は3日');
};

subtest 'Before: 定期購入 × クレジットカード' => sub {
    my $result = $proc->process(
        SubscriptionOrder->new(monthly_amount => 1000),
        CreditCard->new,
    );
    is($result->{method},    'credit',   '決済方法はcredit');
    is($result->{amount},    1000,       '金額は月額1000');
    is($result->{status},    'enrolled', 'ステータスはenrolled');
    is($result->{recurring}, 1,          '継続課金フラグあり');
};

subtest 'Before: 定期購入 × 銀行振込' => sub {
    my $result = $proc->process(
        SubscriptionOrder->new(monthly_amount => 1500),
        BankTransfer->new,
    );
    is($result->{method},    'bank',    '決済方法はbank');
    is($result->{amount},    1500,      '金額は月額1500');
    is($result->{due_days},  14,        '支払期限は14日');
    is($result->{recurring}, 1,         '継続課金フラグあり');
};

subtest 'Before: 定期購入 × コンビニ払い → エラー' => sub {
    eval {
        $proc->process(
            SubscriptionOrder->new(monthly_amount => 1000),
            ConvenienceStore->new,
        );
    };
    like($@, qr/定期購入にコンビニ払いは未対応/, '未対応の組み合わせでdie');
};

subtest 'Before: 予約注文 × クレジットカード' => sub {
    my $result = $proc->process(
        PreOrder->new(total => 8000, deposit => 2000),
        CreditCard->new,
    );
    is($result->{method}, 'credit',     '決済方法はcredit');
    is($result->{amount}, 0,            '即時請求額は0');
    is($result->{status}, 'authorized', 'ステータスはauthorized');
    is($result->{hold},   8000,         'オーソリ金額は8000');
};

subtest 'Before: 予約注文 × 銀行振込' => sub {
    my $result = $proc->process(
        PreOrder->new(total => 8000, deposit => 2000),
        BankTransfer->new,
    );
    is($result->{method},   'bank',    '決済方法はbank');
    is($result->{amount},   8000,      '金額は8000');
    is($result->{due_days}, 30,        '支払期限は30日');
};

subtest 'Before: 予約注文 × コンビニ払い' => sub {
    my $result = $proc->process(
        PreOrder->new(total => 8000, deposit => 2000),
        ConvenienceStore->new,
    );
    is($result->{method},     'convenience', '決済方法はconvenience');
    is($result->{amount},     2000,          '内金2000');
    is($result->{expires_in}, 7,             '有効期限は7日');
};

done_testing;
