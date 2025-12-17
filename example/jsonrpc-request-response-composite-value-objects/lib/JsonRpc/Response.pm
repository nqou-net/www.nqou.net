package JsonRpc::Response;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Any Maybe Str Int);
use JsonRpc::Version;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);
has result => (
    is  => 'ro',
    isa => Any,
    required => 1,
);
has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
    required => 1,
);

sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: result"
        unless exists $hash->{result};
    die "missing required field: id"
        unless exists $hash->{id};
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        result  => $hash->{result},
        id      => $hash->{id},
    );
}   

sub to_hash {
    my $self = shift;
    
    return {
        jsonrpc => $self->jsonrpc->value,
        result  => $self->result,
        id      => $self->id,
    };
}

1;
