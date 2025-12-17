use Test2::V0 -target => 'JsonRpc::Types';

    use JsonRpc::Types qw(JsonRpcParams JsonRpcId JsonRpcVersion);
    
    has params => (is => 'ro', isa => Maybe[JsonRpcParams]);
    has id     => (is => 'ro', isa => Maybe[JsonRpcId]);
