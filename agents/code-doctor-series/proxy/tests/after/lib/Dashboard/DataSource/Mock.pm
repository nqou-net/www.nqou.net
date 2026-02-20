package Dashboard::DataSource::Mock;
use v5.36;
use parent 'Dashboard::DataSource';

# テスト用 Mock Proxy — 実DB/APIなしでテスト可能

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{sales_data} = delete $args{sales_data} // [];
    $self->{rates}      = delete $args{rates}      // {};
    $self->{call_log}   = [];
    return $self;
}

sub fetch_sales_summary ($self, $year, $month) {
    push $self->{call_log}->@*, {method => 'fetch_sales_summary', args => [$year, $month]};
    return $self->{sales_data};
}

sub fetch_exchange_rate ($self, $currency) {
    push $self->{call_log}->@*, {method => 'fetch_exchange_rate', args => [$currency]};
    return $self->{rates}{$currency} // die "Unknown currency: $currency";
}

# テスト用: 呼び出し履歴の取得
sub call_log ($self) {
    return $self->{call_log}->@*;
}

# テスト用: 特定メソッドの呼び出し回数
sub call_count ($self, $method) {
    return scalar grep { $_->{method} eq $method } $self->{call_log}->@*;
}

1;
