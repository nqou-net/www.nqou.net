use v5.36;
use Test::More;

# テストしたいけど、実DBと実APIがないと動かない…
# TODO: モック入れたいが、直接DBI->connectしてるからどうにもならん

# とりあえずモジュールが読み込めることだけ確認
use_ok('Dashboard');

# render_dashboard は実DB・実APIに依存するため、
# CIではスキップ
SKIP: {
    skip "requires live DB and API", 1 unless $ENV{LIVE_TEST};

    my $result = Dashboard::render_dashboard(2026, 1);
    ok($result->{jpy_summary}, 'JPY summary exists');
    ok($result->{usd_summary}, 'USD summary exists');
    ok($result->{rates}{USD},  'USD rate exists');
}

done_testing;
