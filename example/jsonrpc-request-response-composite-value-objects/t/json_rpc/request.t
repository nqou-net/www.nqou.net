use v5.38;
use Test2::V0 -target => 'JsonRpc::Request';

use JsonRpc::Version;
use JsonRpc::MethodName;

subtest 'constructor with required fields only' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'getUser'),
    );
    
    ok $req, 'Request created with required fields';
    isa_ok $req->jsonrpc, 'JsonRpc::Version';
    isa_ok $req->method,  'JsonRpc::MethodName';
    is $req->params, undef, 'params is undef by default';
    is $req->id,     undef, 'id is undef by default';
};

subtest 'constructor with all fields' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'createUser'),
        params  => { name => 'Alice', age => 30 },
        id      => 'req-001',
    );
    
    ok $req, 'Request created with all fields';
    is $req->params, { name => 'Alice', age => 30 }, 'params is hash';
    is $req->id, 'req-001', 'id is string';
};

subtest 'constructor rejects invalid jsonrpc' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => "not a Version object",
                method  => JsonRpc::MethodName->new(value => 'test'),
            );
        },
        qr/type constraint|isa/i,
        'rejects non-Version jsonrpc'
    );
};

subtest 'constructor rejects invalid method' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => JsonRpc::Version->new(value => '2.0'),
                method  => "not a MethodName object",
            );
        },
        qr/type constraint|isa/i,
        'rejects non-MethodName method'
    );
};

subtest 'params accepts array or hash or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');
    
    # ArrayRef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => [1, 2, 3],
        );
    }, 'params accepts ArrayRef');
    
    # HashRef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => { key => 'value' },
        );
    }, 'params accepts HashRef');
    
    # undef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => undef,
        );
    }, 'params accepts undef');
    
    # String は拒否
    like(dies {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => "string",
        );
    }, qr/type constraint/i, 'params rejects string');
};

subtest 'id accepts string, int, or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 'str-id');
    }, 'id accepts string');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 123);
    }, 'id accepts integer');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => undef);
    }, 'id accepts undef');
    
    like(dies {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => []);
    }, qr/type constraint/i, 'id rejects array reference');
};

subtest 'from_hash factory method' => sub {
    subtest 'creates request from hash' => sub {
        my $req = JsonRpc::Request->from_hash({
            jsonrpc => '2.0',
            method  => 'getUser',
            params  => { user_id => 42 },
            id      => 'req-001',
        });
        
        isa_ok $req,['JsonRpc::Request'], 'is a JsonRpc::Request';
        is $req->jsonrpc->value, '2.0', 'jsonrpc is correct';
        is $req->method->value, 'getUser', 'method is correct';
        is $req->params, { user_id => 42 }, 'params is correct';
        is $req->id, 'req-001', 'id is correct';
    };
    
    subtest 'from_hash with minimal fields' => sub {
        my $req = JsonRpc::Request->from_hash({
            jsonrpc => '2.0',
            method  => 'notify',
        });
        
        isa_ok $req,['JsonRpc::Request'], 'is a JsonRpc::Request';
        is $req->jsonrpc->value, '2.0', 'jsonrpc is correct';
        is $req->method->value, 'notify', 'method is correct';
        is $req->params, undef, 'params defaults to undef';
        is $req->id, undef, 'id defaults to undef';
    };
    
    subtest 'from_hash rejects missing required fields' => sub {
        like(dies {
            JsonRpc::Request->from_hash({ method => 'test' });
        }, qr/missing.*jsonrpc/i, 'missing jsonrpc rejected');
        
        like(dies {
            JsonRpc::Request->from_hash({ jsonrpc => '2.0' });
        }, qr/missing.*method/i, 'missing method rejected');
    };
    
    subtest 'from_hash rejects non-hash' => sub {
        like(dies {
            JsonRpc::Request->from_hash("not a hash");
        }, qr/hash reference/i, 'string rejected');
        
        like(dies {
            JsonRpc::Request->from_hash([]);
        }, qr/hash reference/i, 'array rejected');
    };
};

subtest 'to_hash converts back to hash' => sub {
    my $req = JsonRpc::Request->from_hash({
        jsonrpc => '2.0',
        method  => 'createUser',
        params  => { name => 'Bob' },
        id      => 123,
    });
    
    my $hash = $req->to_hash;
    
    is $hash, {
        jsonrpc => '2.0',
        method  => 'createUser',
        params  => { name => 'Bob' },
        id      => 123,
    }, 'to_hash produces correct hash';
};

done_testing;
