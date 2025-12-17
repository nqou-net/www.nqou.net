package JsonRpc::Types;
use v5.38;
use Type::Library -base;
use Types::Standard qw(:all);

use Type::Utils -all;

# JsonRpcParams型 - ArrayRef または HashRef
declare "JsonRpcParams",
    as ArrayRef | HashRef;

# JsonRpcId型 - Str, Int, Null のいずれか（ただしNull以外）
declare "JsonRpcId",
    as Str | Int;

# JsonRpcVersion型 - "2.0" という文字列のみ
declare "JsonRpcVersion",
    as Str,
    where { $_ eq '2.0' },
    message { "JSON-RPC version must be '2.0', got '$_'" };

1;

__END__

=head1 NAME

JsonRpc::Types - Type constraints for JSON-RPC 2.0

=head1 SYNOPSIS

    use JsonRpc::Types qw(JsonRpcParams JsonRpcId JsonRpcVersion);
    
    has params => (is => 'ro', isa => Maybe[JsonRpcParams]);
    has id     => (is => 'ro', isa => Maybe[JsonRpcId]);

=head1 DESCRIPTION

This module provides custom type constraints for JSON-RPC 2.0 implementation.

=cut
