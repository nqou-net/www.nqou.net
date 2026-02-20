package Dashboard;
use v5.36;

use DBI;
use HTTP::Tiny;
use JSON::PP qw(decode_json);

# DB接続情報（ベタ書き）
my $DSN  = "dbi:SQLite:dbname=dashboard.db";
my $USER = "";
my $PASS = "";

# --- 売上サマリー ---
sub get_sales_summary ($year, $month) {
    my $dbh = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1 });
    my $rows = $dbh->selectall_arrayref(
        "SELECT product, SUM(amount) as total FROM sales WHERE year=? AND month=? GROUP BY product",
        { Slice => {} }, $year, $month
    );
    $dbh->disconnect;
    return $rows;
}

# --- 為替レート取得 ---
# NOTE: なぜか各関数で個別に取得してる。まとめたいけど動いてるから触らない
sub _fetch_exchange_rate ($currency) {
    my $http = HTTP::Tiny->new(timeout => 5);
    my $res  = $http->get("https://api.exchange.example.com/latest?base=JPY&symbols=$currency");
    die "API error: $res->{status}" unless $res->{success};
    my $data = decode_json($res->{content});
    return $data->{rates}{$currency};
}

# --- 売上サマリー（USD換算） ---
sub get_sales_summary_usd ($year, $month) {
    # 売上データを取得（get_sales_summaryと同じクエリだけど、ここでも直接叩く）
    my $dbh = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1 });
    my $rows = $dbh->selectall_arrayref(
        "SELECT product, SUM(amount) as total FROM sales WHERE year=? AND month=? GROUP BY product",
        { Slice => {} }, $year, $month
    );
    $dbh->disconnect;

    my $rate = _fetch_exchange_rate('USD');  # ここでもAPI叩く
    return [ map { { $_->%*, total_usd => $_->{total} * $rate } } $rows->@* ];
}

# --- 売上サマリー（EUR換算） ---
sub get_sales_summary_eur ($year, $month) {
    # またDBに同じクエリ…
    my $dbh = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1 });
    my $rows = $dbh->selectall_arrayref(
        "SELECT product, SUM(amount) as total FROM sales WHERE year=? AND month=? GROUP BY product",
        { Slice => {} }, $year, $month
    );
    $dbh->disconnect;

    my $rate = _fetch_exchange_rate('EUR');  # またAPI叩く
    return [ map { { $_->%*, total_eur => $_->{total} * $rate } } $rows->@* ];
}

# --- ダッシュボード全体のレンダリング ---
sub render_dashboard ($year, $month) {
    my $jpy = get_sales_summary($year, $month);            # 1回目のDBクエリ
    my $usd = get_sales_summary_usd($year, $month);        # 2回目（同じクエリ） + API
    my $eur = get_sales_summary_eur($year, $month);         # 3回目（同じクエリ） + API

    # 為替レートも表示用に取得（さらにAPI 2回）
    my $usd_rate = _fetch_exchange_rate('USD');
    my $eur_rate = _fetch_exchange_rate('EUR');

    return {
        jpy_summary  => $jpy,
        usd_summary  => $usd,
        eur_summary  => $eur,
        rates        => { USD => $usd_rate, EUR => $eur_rate },
    };
}

1;
