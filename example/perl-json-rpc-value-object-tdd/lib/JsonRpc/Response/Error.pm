package JsonRpc::Response::Error;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Maybe Str Int InstanceOf);
use Type::Utils qw(union);
use JsonRpc::Version;
use JsonRpc::Error;
use namespace::clean;

has version => (
  is      => 'ro',
  isa     => InstanceOf['JsonRpc::Version'],
  default => sub { JsonRpc::Version->new('2.0') },
);

has error => (
  is       => 'ro',
  isa      => InstanceOf['JsonRpc::Error'],
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
    error   => $self->error->to_hash,
    id      => $self->id,
  };
}

1;
