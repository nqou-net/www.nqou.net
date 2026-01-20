package PasswordLock;
use Moo;
use experimental qw(signatures);

has _secret => (
    is      => 'ro',
    default => '777',
);

sub unlock ($self, $attempt) {
    if ($attempt eq $self->_secret) {
        return 1;
    }
    return 0;
}

1;
