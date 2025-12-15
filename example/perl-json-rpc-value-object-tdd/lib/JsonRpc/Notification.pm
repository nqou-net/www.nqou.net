package JsonRpc::Notification;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef Maybe InstanceOf);
use Type::Utils qw(union declare as where message);
use JsonRpc::Version;
use namespace::clean;

has version => (
  is      => 'ro',
  isa     => InstanceOf['JsonRpc::Version'],
  default => sub { JsonRpc::Version->new('2.0') },
);

# メソッド名の制約（Requestと同じ）
my $MethodName = declare as Str,
  where   { $_ !~ /^rpc\./ },
    message { "Method name must not start with 'rpc.': got '$_'" };

has method => (
  is       => 'ro',
  isa      => $MethodName,
  required => 1,
);

my $ParamsType = Maybe[ArrayRef | HashRef];

has params => (
  is  => 'ro',
  isa => $ParamsType,
);

sub to_hash {
  my $self = shift;

  my %hash = (
    jsonrpc => $self->version->value,
    method  => $self->method,
  );

  $hash{params} = $self->params if defined $self->params;

  return \%hash;
}

1;
