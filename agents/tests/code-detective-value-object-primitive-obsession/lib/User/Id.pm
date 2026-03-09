package User::Id;

use strict;
use warnings;
use Moo;
use Types::Standard qw(Int);

has value => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    die "ID must be positive" if $self->value <= 0;
}

sub TO_JSON {
    my ($self) = @_;
    return $self->value + 0; # 確実に数値として出力
}

1;
