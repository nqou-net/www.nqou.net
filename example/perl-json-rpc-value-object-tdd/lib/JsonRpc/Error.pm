package JsonRpc::Error;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Int Str Any Maybe);
use Type::Utils qw(declare as where message);
use namespace::clean;

# 標準エラーコードの定数
use constant {
  PARSE_ERROR      => -32700,
  INVALID_REQUEST  => -32600,
  METHOD_NOT_FOUND => -32601,
  INVALID_PARAMS   => -32602,
  INTERNAL_ERROR   => -32603,
};
# 定数のエクスポート機能を追加
use Exporter 'import';
our @EXPORT_OK = qw(
  PARSE_ERROR
  INVALID_REQUEST
  METHOD_NOT_FOUND
  INVALID_PARAMS
  INTERNAL_ERROR
);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);
# エラーコードの型制約
my $ErrorCode = declare as Int,
  where {
    # -32768 〜 -32000: 予約済み（標準エラー）
    # -32099 〜 -32000: サーバー定義可能
    ($_ >= -32768 && $_ <= -32000)
  },
    message { "Invalid error code: must be in reserved range, got $_" };

has code => (
  is       => 'ro',
  isa      => $ErrorCode,
  required => 1,
);

has message => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has data => (
  is  => 'ro',
  isa => Maybe[Any],
);

sub to_hash {
  my $self = shift;

  my %hash = (
    code    => $self->code,
    message => $self->message,
  );

  $hash{data} = $self->data if defined $self->data;

  return \%hash;
}

1;
