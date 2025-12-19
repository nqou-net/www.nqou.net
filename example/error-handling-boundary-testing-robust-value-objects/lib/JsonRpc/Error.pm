package JsonRpc::Error;
use v5.38;
use Moo;
use Types::Standard qw(Int Str Any Maybe);
use namespace::clean;

has code => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => sub {
        my $val = shift;
        die "message must be a string"
            unless defined $val && !ref $val;
        die "message cannot be empty"
            if $val eq '';
    },
    required => 1,
);

has data => (
    is  => 'ro',
    isa => Any,  # 任意の型を許容
);

1;
