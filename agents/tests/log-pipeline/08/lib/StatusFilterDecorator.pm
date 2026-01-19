package StatusFilterDecorator;
use Moo;
use experimental qw(signatures);

extends 'LogDecorator';

has target_status => ( is => 'ro', required => 1 );

around next_log => sub ($orig, $self) {
    while (defined(my $log = $self->$orig)) {
        if ($log->{status} eq $self->target_status) {
            return $log;
        }
    }
    return undef;
};

1;
