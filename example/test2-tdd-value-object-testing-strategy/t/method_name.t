use Test2::V0 -target => 'JsonRpc::MethodName';

subtest 'constructor accepts valid method name' => sub {
    my $method = JsonRpc::MethodName->new(value => 'getUser');
    
    ok $method, 'object created';
    is $method->value, 'getUser', 'value is correct';
};

subtest 'constructor rejects empty string' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => '') },
        qr/method name cannot be empty/i,
        'empty string is rejected'
    );
};

subtest 'constructor rejects undef' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => undef) },
        qr/method name cannot be empty/i,
        'undef is rejected'
    );
};

subtest 'constructor rejects non-string types' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => []) },
        qr/must be.*string/i,
        'array reference is rejected'
    );
    
    like(
        dies { JsonRpc::MethodName->new(value => {}) },
        qr/must be.*string/i,
        'hash reference is rejected'
    );
};

subtest 'reserved method name "rpc." prefix is rejected' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => 'rpc.internal') },
        qr/reserved/i,
        '"rpc." prefix is reserved'
    );
    
    # "rpc" だけならOK
    ok(lives { JsonRpc::MethodName->new(value => 'rpcMethod') },
       '"rpc" without dot is ok');
};


done_testing;
