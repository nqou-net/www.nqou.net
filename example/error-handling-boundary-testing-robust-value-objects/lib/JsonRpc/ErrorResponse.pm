package JsonRpc::ErrorResponse;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Str Int Maybe);
use JsonRpc::Version;
use JsonRpc::Error;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has error => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Error'],
    required => 1,
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],  # エラー時はnullの可能性あり
);

sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: error"
        unless exists $hash->{error};
    
    # resultフィールドがあれば拒否（排他性）
    die "ErrorResponse must not have 'result' field"
        if exists $hash->{result};
    
    my $error_obj;
    if (ref $hash->{error} eq 'HASH') {
        # Errorオブジェクトをネストで構築
        $error_obj = JsonRpc::Error->new(
            code    => $hash->{error}{code},
            message => $hash->{error}{message},
            exists $hash->{error}{data} ? (data => $hash->{error}{data}) : (),
        );
    } elsif (ref $hash->{error} eq 'JsonRpc::Error') {
        $error_obj = $hash->{error};
    } else {
        die "error field must be a hash or JsonRpc::Error object";
    }
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        error   => $error_obj,
        exists $hash->{id} ? (id => $hash->{id}) : (),
    );
}

sub to_hash {
    my $self = shift;
    
    my $hash = {
        jsonrpc => $self->jsonrpc->value,
        error   => {
            code    => $self->error->code,
            message => $self->error->message,
        },
    };
    
    # dataが存在する場合のみ追加
    $hash->{error}{data} = $self->error->data
        if defined $self->error->data;
    
    # idが存在する場合のみ追加
    $hash->{id} = $self->id
        if defined $self->id;
    
    return $hash;
}

1;
