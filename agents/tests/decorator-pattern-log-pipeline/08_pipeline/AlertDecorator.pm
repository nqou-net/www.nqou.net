package AlertDecorator;
use Moo;
use experimental qw(signatures);

extends 'LogDecorator';

# アラートの閾値（デフォルトは3回連続）
has threshold => ( is => 'ro', default => 3 );

# 連続エラー回数を保持するプライベートアトリビュート
has _consecutive_404s => ( is => 'rw', default => 0 );

around next_log => sub ($orig, $self) {
    my $log = $self->$orig;

    if ($log) {
        if ($log->{status} eq '404') {
            # 404ならカウントアップ
            $self->_consecutive_404s( $self->_consecutive_404s + 1 );

            # 閾値を超えたらアラート！
            if ($self->_consecutive_404s >= $self->threshold) {
                warn "[ALERT] Too many 404s! Consecutive count: " . $self->_consecutive_404s . "\n";
                # ここでSlack通知などを送ることも可能
            }
        } else {
            # 404以外が来たらリセット
            $self->_consecutive_404s(0);
        }
    }

    return $log;
};

1;
