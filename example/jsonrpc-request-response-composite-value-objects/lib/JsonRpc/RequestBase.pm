package JsonRpc::RequestBase;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Maybe ArrayRef HashRef);
use JsonRpc::Version;
use JsonRpc::MethodName;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf ['JsonRpc::Version'],
    required => 1,
);

has method => (
    is       => 'ro',
    isa      => InstanceOf ['JsonRpc::MethodName'],
    required => 1,
);

has params => (
    is  => 'ro',
    isa => Maybe [ArrayRef | HashRef],
);

1;
