package JsonRpc::Request;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Maybe ArrayRef HashRef Str Int);
use JsonRpc::Version;
use JsonRpc::MethodName;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has method => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::MethodName'],
    required => 1,
);

has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef],
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
);

# ファクトリーメソッド: HashRef から Request を生成
sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    # 必須フィールドの存在チェック
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: method"
        unless exists $hash->{method};
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        method  => JsonRpc::MethodName->new(value => $hash->{method}),
        exists $hash->{params} ? (params => $hash->{params}) : (),
        exists $hash->{id}     ? (id     => $hash->{id})     : (),
    );
}

# JSON文字列への変換
sub to_hash {
    my $self = shift;
    
    my $hash = {
        jsonrpc => $self->jsonrpc->value,
        method  => $self->method->value,
    };
    
    $hash->{params} = $self->params if defined $self->params;
    $hash->{id}     = $self->id     if defined $self->id;
    
    return $hash;
}

1;

__END__

=head1 METHODS

=head2 from_hash

Creates a Request object from a hash reference (typically from decoded JSON).

    my $req = JsonRpc::Request->from_hash({
        jsonrpc => '2.0',
        method  => 'getUser',
        params  => { user_id => 42 },
        id      => 'req-123',
    });

=head2 to_hash

Converts the Request object back to a hash reference suitable for JSON encoding.

    my $hash = $req->to_hash;
    # { jsonrpc => '2.0', method => 'getUser', ... }

=cut
