package Dashboard::DataSource;
use v5.36;

# データソースのインターフェース（Subject）
# RealSubjectとProxyが共通のインターフェースを持つ

sub new ($class, %args) {
    return bless \%args, $class;
}

# --- DB系 ---
sub fetch_sales_summary ($self, $year, $month) {...}

# --- API系 ---
sub fetch_exchange_rate ($self, $currency) {...}

1;
