package StatsAggregatorDecorator;
use Moo;
use experimental qw(signatures);

extends 'LogDecorator';

# 統計情報を保持するハッシュ（状態）
has stats => (
    is      => 'ro',
    default => sub { { status_count => {}, total_size => 0, total_requests => 0 } },
);

around next_log => sub ($orig, $self) {
    # 1. 中身（wrapped）からログを取得
    my $log = $self->$orig;

    # 2. ログが存在すれば集計（状態の更新）
    if ($log) {
        $self->stats->{total_requests}++;
        $self->stats->{total_size} += ($log->{size} eq '-' ? 0 : $log->{size});
        $self->stats->{status_count}->{ $log->{status} }++;
    }

    # 3. ログをそのまま返す（パススルー）
    return $log;
};

# 集計結果を表示するメソッド
sub report ($self) {
    my $s = $self->stats;
    print "=== Log Stats ===\n";
    print "Total Requests: $s->{total_requests}\n";
    print "Total Size:     $s->{total_size} bytes\n";
    print "Status Codes:\n";
    for my $code (sort keys %{ $s->{status_count} }) {
        print "  $code: $s->{status_count}->{$code}\n";
    }
    print "=================\n";
}

1;
