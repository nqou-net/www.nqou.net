package JsonRpc::Response::Success;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Any Maybe Str Int InstanceOf);
use Type::Utils qw(union);
use JsonRpc::Version;
use namespace::clean;

has version => (
  is      => 'ro',
  isa     => InstanceOf['JsonRpc::Version'],
  default => sub { JsonRpc::Version->new('2.0') },
);

has result => (
  is       => 'ro',
  isa      => Any,
  required => 1,
);

my $IdType = Maybe[Str | Int];

has id => (
  is       => 'ro',
  isa      => $IdType,
  required => 1,
);

sub to_hash {
  my $self = shift;
  return {
    jsonrpc => $self->version->value,
    result  => $self->result,
    id      => $self->id,
  };
}

1;
