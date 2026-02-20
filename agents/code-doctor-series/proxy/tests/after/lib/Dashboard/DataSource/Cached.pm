package Dashboard::DataSource::Cached;
use v5.36;
use parent 'Dashboard::DataSource';

# Caching Proxy — 同一引数の呼び出し結果をキャッシュ
# RealSubject と同じインターフェースを持つ

sub new ($class, %args) {
    my $real = delete $args{real_source} // die "real_source is required";
    my $self = $class->SUPER::new(%args);
    $self->{real}  = $real;
    $self->{cache} = {};
    return $self;
}

sub fetch_sales_summary ($self, $year, $month) {
    my $key = "sales:$year:$month";
    return $self->{cache}{$key} if exists $self->{cache}{$key};

    my $result = $self->{real}->fetch_sales_summary($year, $month);
    $self->{cache}{$key} = $result;
    return $result;
}

sub fetch_exchange_rate ($self, $currency) {
    my $key = "rate:$currency";
    return $self->{cache}{$key} if exists $self->{cache}{$key};

    my $result = $self->{real}->fetch_exchange_rate($currency);
    $self->{cache}{$key} = $result;
    return $result;
}

# キャッシュのクリア（必要に応じて）
sub clear_cache ($self) {
    $self->{cache} = {};
    return $self;
}

1;
