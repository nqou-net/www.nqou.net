package JsonRpc::Request;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef Maybe Int Defined InstanceOf);
use Type::Utils qw(declare as where message);
use JsonRpc::Version;
use namespace::clean;

# バージョン（自動的に'2.0'）
has version => (
  is      => 'ro',
  isa     => InstanceOf [ 'JsonRpc::Version' ],
  default => sub {JsonRpc::Version->new('2.0')},
);

# メソッド名は rpc. で始まってはいけない（予約済み）
my $MethodName = declare as Str,
  where {$_ !~ /^rpc\./},
    message {"Method name must not start with 'rpc.': got '$_'"};

has method => (
  is       => 'ro',
  isa      => $MethodName,
  required => 1,
);

# パラメータ（配列またはハッシュ、省略可）
my $ParamsType = Maybe [ ArrayRef | HashRef ];

has params => (
  is  => 'ro',
  isa => $ParamsType,
);

# ID（文字列・数値・null、必須）
my $IdType = Maybe [ Str | Int ];

has id => (
  is       => 'ro',
  isa      => $IdType,
  required => 1,
);

# ハッシュ表現に変換
sub to_hash {
  my $self = shift;

  my %hash = (
    jsonrpc => $self->version->value,
    method  => $self->method,
    id      => $self->id,
  );

  $hash{params} = $self->params if defined $self->params;

  return \%hash;
}

1;
