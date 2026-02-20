use v5.36;
use Test::More;
use lib 'lib';

# --- モジュール読み込みテスト ---
use_ok('Dashboard');
use_ok('Dashboard::DataSource');
use_ok('Dashboard::DataSource::Mock');
use_ok('Dashboard::DataSource::Cached');

# --- Mock Proxy のテスト ---
subtest 'Mock Proxy returns preset data' => sub {
    my $mock = Dashboard::DataSource::Mock->new(
        sales_data => [{product => 'Widget', total => 1000}, {product => 'Gadget', total => 2000},],
        rates      => {USD => 0.0067, EUR => 0.0061},
    );

    my $sales = $mock->fetch_sales_summary(2026, 1);
    is(scalar $sales->@*,    2,        'returns 2 products');
    is($sales->[0]{product}, 'Widget', 'first product is Widget');
    is($sales->[0]{total},   1000,     'Widget total is 1000');

    my $rate = $mock->fetch_exchange_rate('USD');
    is($rate, 0.0067, 'USD rate is 0.0067');

    is($mock->call_count('fetch_sales_summary'), 1, 'sales called once');
    is($mock->call_count('fetch_exchange_rate'), 1, 'rate called once');
};

# --- Caching Proxy のテスト ---
subtest 'Caching Proxy caches results' => sub {
    my $mock = Dashboard::DataSource::Mock->new(
        sales_data => [{product => 'Widget', total => 1000},],
        rates      => {USD => 0.0067, EUR => 0.0061},
    );

    my $cached = Dashboard::DataSource::Cached->new(real_source => $mock);

    # 同じ引数で3回呼ぶ
    $cached->fetch_sales_summary(2026, 1);
    $cached->fetch_sales_summary(2026, 1);
    $cached->fetch_sales_summary(2026, 1);

    # MockProxy（RealSubject役）には1回しか到達していない
    is($mock->call_count('fetch_sales_summary'), 1, 'real source called only once despite 3 calls');

    # 為替レートも同様
    $cached->fetch_exchange_rate('USD');
    $cached->fetch_exchange_rate('USD');
    is($mock->call_count('fetch_exchange_rate'), 1, 'exchange rate fetched only once despite 2 calls');

    # 異なる引数は別キー
    $cached->fetch_exchange_rate('EUR');
    is($mock->call_count('fetch_exchange_rate'), 2, 'different currency triggers new fetch');
};

# --- Dashboard + Caching Proxy 統合テスト ---
subtest 'Dashboard with Cached Proxy minimizes calls' => sub {
    my $mock = Dashboard::DataSource::Mock->new(
        sales_data => [{product => 'Widget', total => 1000}, {product => 'Gadget', total => 2000},],
        rates      => {USD => 0.0067, EUR => 0.0061},
    );

    my $cached    = Dashboard::DataSource::Cached->new(real_source => $mock);
    my $dashboard = Dashboard->new(data_source => $cached);

    my $result = $dashboard->render(2026, 1);

    # 結果の検証
    is(scalar $result->{jpy_summary}->@*, 2, 'JPY summary has 2 items');
    is(scalar $result->{usd_summary}->@*, 2, 'USD summary has 2 items');
    is(scalar $result->{eur_summary}->@*, 2, 'EUR summary has 2 items');

    # USD変換の検証
    is($result->{usd_summary}[0]{total_usd}, 1000 * 0.0067, 'USD conversion correct');

    # レートの検証
    is($result->{rates}{USD}, 0.0067, 'USD rate in result');
    is($result->{rates}{EUR}, 0.0061, 'EUR rate in result');

    # 重要: render内で fetch_sales_summary が3回呼ばれるが、
    # Caching Proxy のおかげで RealSubject には1回しか到達しない
    is($mock->call_count('fetch_sales_summary'), 1, 'sales query hit real source only ONCE (was 3 times in Before!)');

    # 為替レートも USD, EUR 各1回ずつ（Before では USD 2回, EUR 2回だった）
    is($mock->call_count('fetch_exchange_rate'), 2, 'exchange rate hit real source only TWICE (was 4 times in Before!)');
};

# --- キャッシュクリアのテスト ---
subtest 'Cache clear works' => sub {
    my $mock = Dashboard::DataSource::Mock->new(
        sales_data => [{product => 'X', total => 100}],
        rates      => {USD => 0.007},
    );

    my $cached = Dashboard::DataSource::Cached->new(real_source => $mock);

    $cached->fetch_sales_summary(2026, 1);
    is($mock->call_count('fetch_sales_summary'), 1, 'first call hits real');

    $cached->clear_cache;
    $cached->fetch_sales_summary(2026, 1);
    is($mock->call_count('fetch_sales_summary'), 2, 'after clear, hits real again');
};

done_testing;
