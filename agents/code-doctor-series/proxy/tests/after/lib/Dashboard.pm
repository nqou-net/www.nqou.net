package Dashboard;
use v5.36;

# Proxy パターン適用後のダッシュボード
# DataSource を差し替え可能（Real / Cached / Mock）

sub new ($class, %args) {
    my $source = delete $args{data_source} // die "data_source is required";
    return bless {source => $source}, $class;
}

sub render ($self, $year, $month) {
    my $source = $self->{source};

    # 何回呼んでも、Cached Proxy なら DB/API は1回だけ
    my $jpy_summary = $source->fetch_sales_summary($year, $month);

    my $usd_rate = $source->fetch_exchange_rate('USD');
    my $eur_rate = $source->fetch_exchange_rate('EUR');

    my $usd_summary = [
        map {
            { $_->%*, total_usd => $_->{total} * $usd_rate }
        } $source->fetch_sales_summary($year, $month)->@*    # キャッシュヒット
    ];

    my $eur_summary = [
        map {
            { $_->%*, total_eur => $_->{total} * $eur_rate }
        } $source->fetch_sales_summary($year, $month)->@*    # キャッシュヒット
    ];

    return {
        jpy_summary => $jpy_summary,
        usd_summary => $usd_summary,
        eur_summary => $eur_summary,
        rates       => {USD => $usd_rate, EUR => $eur_rate},
    };
}

1;
