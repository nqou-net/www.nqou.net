package JsonRpc::Version;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str);
use Type::Utils qw(declare as where message);
use namespace::clean;

# カスタム型制約を定義
my $JsonRpcVersionStr = declare as Str,
  where   { $_ eq '2.0' },
    message { "Invalid version: must be '2.0', got '$_'" };

has value => (
  is       => 'ro',
  isa      => $JsonRpcVersionStr,  # カスタム型を使用
  required => 1,
  coerce   => 1,
);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  return { value => $args[0] } if @args == 1 && !ref $args[0];
  return $class->$orig(@args);
};

sub equals {
  my ($self, $other) = @_;
  return 0 unless $other && $other->isa(__PACKAGE__);
  return $self->value eq $other->value;
}

1;
