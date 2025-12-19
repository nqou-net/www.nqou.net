package JsonRpc::Request;
use v5.38;
use Moo;
extends 'JsonRpc::RequestBase';
use Types::Standard qw(Maybe Str Int);
use namespace::clean;

has id => (
    is       => 'ro',
    isa      => Maybe [Str | Int],
    required => 1,                   # 必須にする
);

1;
