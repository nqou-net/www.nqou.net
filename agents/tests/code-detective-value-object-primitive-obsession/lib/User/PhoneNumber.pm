package User::PhoneNumber;

use strict;
use warnings;
use Moo;
use Types::Standard qw(Str);

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    die "Invalid phone number" unless $self->value =~ /^\d{10,11}$/;
}

# JSON::MaybeXS (convert_blessed) などで呼ばれる
sub TO_JSON {
    my ($self) = @_;
    return "" . $self->value; # 確実に文字列として出力
}

1;
