package BruteForceIterator;
use Moo;
use experimental qw(signatures);

has length => (
    is       => 'ro',
    required => 1,
);

has _current => (
    is      => 'rw',
    default => 0,
);

has _max => (
    is      => 'lazy',
    builder => sub ($self) {
        return 10 ** $self->length;
    },
);

sub next ($self) {
    my $val = $self->_current;

    if ($val >= $self->_max) {
        return undef;
    }

    $self->_current($val + 1);

    return sprintf("%0*d", $self->length, $val);
}

1;
