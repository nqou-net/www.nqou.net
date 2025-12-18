use v5.38;
use Test2::V0 -target => 'JsonRpc::Request';

use JsonRpc::Version;
use JsonRpc::MethodName;

subtest 'constructor with required fields only' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'ping'),
        id      => undef,
    );

    isa_ok $req,          ['JsonRpc::Request'];
    isa_ok $req->jsonrpc, ['JsonRpc::Version'];
    isa_ok $req->method,  ['JsonRpc::MethodName'];
    is $req->method->value, 'ping', 'method value is ping';
    is $req->params,        undef,  'params is undef by default';
    is $req->id,            undef,  'id is undef';
};

subtest 'constructor with all fields' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'createUser'),
        params  => {name => 'Alice', age => 30},
        id      => 'req-001',
    );

    isa_ok $req, ['JsonRpc::Request'];
    is $req->method->value, 'createUser', 'method value is createUser';
    is $req->params, {name => 'Alice', age => 30}, 'params is hash';
    is $req->id, 'req-001', 'id is string';
};

subtest 'constructor rejects invalid jsonrpc' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => "not a Version object",
                method  => JsonRpc::MethodName->new(value => 'test'),
                id      => undef,
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
                id      => undef,
            );
        },
        qr/type constraint|isa/i,
        'rejects non-MethodName method'
    );
};

subtest 'constructor rejects missing id' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => JsonRpc::Version->new(value => '2.0'),
                method  => "not a MethodName object",
            );
        },
        qr/required/i,
        'rejects missing id'
    );
};

subtest 'params accepts array or hash or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');

    # ArrayRef
    ok(
        lives {
            JsonRpc::Request->new(
                jsonrpc => $version,
                method  => $method,
                params  => [1, 2, 3],
                id      => 1,
            );
        },
        'params accepts ArrayRef'
    );

    # HashRef
    ok(
        lives {
            JsonRpc::Request->new(
                jsonrpc => $version,
                method  => $method,
                params  => {key => 'value'},
                id      => 1,
            );
        },
        'params accepts HashRef'
    );

    # undef
    ok(
        lives {
            JsonRpc::Request->new(
                jsonrpc => $version,
                method  => $method,
                params  => undef,
                id      => 1,
            );
        },
        'params accepts undef'
    );

    # String は拒否
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => $version,
                method  => $method,
                params  => "string",
                id      => 1,
            );
        },
        qr/type constraint/i,
        'params rejects string'
    );
};

subtest 'id accepts string, int, or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');

    ok(
        lives {
            JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 'str-id');
        },
        'id accepts string'
    );

    ok(
        lives {
            JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 123);
        },
        'id accepts integer'
    );

    ok(
        lives {
            JsonRpc::Request->new(jsonrpc => $version, method => $method, id => undef);
        },
        'id accepts undef'
    );

    like(
        dies {
            JsonRpc::Request->new(jsonrpc => $version, method => $method, id => []);
        },
        qr/type constraint/i,
        'id rejects array reference'
    );
};

done_testing;
