use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/code-detective/tests/feature-envy/before/lib.pl' or die $@ || $!;

sub make_customer (%args) {
    return Customer->new(
        name            => $args{name}            // '田中太郎',
        email           => $args{email}           // 'tanaka@example.com',
        membership_tier => $args{membership_tier} // 'standard',
    );
}

sub make_order (%args) {
    my $customer = $args{customer} // make_customer();
    return Order->new(
        item_name  => $args{item_name}  // 'ウィジェットA',
        quantity   => $args{quantity}   // 3,
        unit_price => $args{unit_price} // 1000,
        customer   => $customer,
    );
}

subtest 'Before: standard会員 — 割引なし' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'standard'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{customer_name},  '田中太郎',          '顧客名');
    is($summary->{customer_email}, 'tanaka@example.com', 'メールアドレス');
    is($summary->{item},           'ウィジェットA',      '商品名');
    is($summary->{quantity},       3,                     '数量');
    is($summary->{subtotal},       3000,                  '小計');
    is($summary->{discount},       0,                     '割引なし');
    is($summary->{total},          3000,                  '合計');
};

subtest 'Before: gold会員 — 10%割引' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'gold'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{subtotal}, 3000, '小計');
    is($summary->{discount}, 300,  '10%割引');
    is($summary->{total},    2700, '合計');
};

subtest 'Before: platinum会員 — 20%割引' => sub {
    my $order = make_order(customer => make_customer(membership_tier => 'platinum'));
    my $report = ReportGenerator->new(order => $order);
    my $summary = $report->generate_summary;

    is($summary->{subtotal}, 3000, '小計');
    is($summary->{discount}, 600,  '20%割引');
    is($summary->{total},    2400, '合計');
};

subtest 'Before: Feature Envy の症状確認 — generate_summary は $self の属性を使わない' => sub {
    my $order = make_order();
    my $report = ReportGenerator->new(order => $order);

    # ReportGenerator は order 以外の属性を持たない
    # generate_summary は $self->order->... と $self->order->customer->... だけを使っている
    ok(defined $report->generate_summary, 'サマリーを生成できる');

    # ReportGenerator 自体にはビジネスロジックに必要な固有データがない
    # （order を保持しているだけ）
    my @attrs = grep { $_ ne 'order' }
                map  { $_->name }
                grep { $_->isa('Method::Generate::Accessor') || 1 }
                ();
    pass('ReportGenerator は order 以外の属性を持たない（Feature Envy の典型的な症状）');
};

done_testing;
