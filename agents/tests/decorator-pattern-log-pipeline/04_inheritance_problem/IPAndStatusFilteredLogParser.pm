package IPAndStatusFilteredLogParser;
use Moo;
use experimental qw(signatures);
extends 'IPFilteredLogParser'; # IPフィルタリング機能を継承

has target_status => ( is => 'ro', required => 1 );

sub next_log ($self) {
    # 親（IPフィルター）のnext_logを呼び出す
    while (defined(my $log = $self->SUPER::next_log)) {
        # さらにステータスコードで判定
        if ($log->{status} eq $self->target_status) {
            return $log;
        }
    }
    return undef;
}
1;
