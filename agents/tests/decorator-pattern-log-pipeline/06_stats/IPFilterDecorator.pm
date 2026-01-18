package IPFilterDecorator;
use Moo;
use experimental qw(signatures);

extends 'LogDecorator';

has target_ip => ( is => 'ro', required => 1 );

# next_logの処理を「包み込む」
around next_log => sub ($orig, $self) {
    # 中身（$orig）からログを取得してループ
    while (defined(my $log = $self->$orig)) {
        # フィルタリング条件
        if ($log->{ip} eq $self->target_ip) {
            return $log;
        }
    }
    return undef;
};

1;
