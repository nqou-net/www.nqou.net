use v5.38;
use Test2::V0 -target => 'JsonRpc::Notification';

use JsonRpc::Version;
use JsonRpc::MethodName;

subtest 'constructor with required fields only' => sub {
    my $req = JsonRpc::Notification->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'notify'),
    );

    isa_ok $req,          ['JsonRpc::Notification'];
    isa_ok $req->jsonrpc, ['JsonRpc::Version'];
    isa_ok $req->method,  ['JsonRpc::MethodName'];
    is $req->method->value, 'notify', 'method value is notify';
    is $req->params,        undef,    'params is undef by default';
};

subtest 'constructor with all fields' => sub {
    my $req = JsonRpc::Notification->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'notifyEvent'),
        params  => [{event => 'event1'}, {event => 'event2'}],
    );

    isa_ok $req, ['JsonRpc::Notification'];
    is $req->method->value, 'notifyEvent',                              'method value is notifyEvent';
    is $req->params,        [{event => 'event1'}, {event => 'event2'}], 'params is array';
};

subtest 'constructor rejects invalid jsonrpc' => sub {
    like(
        dies {
            JsonRpc::Notification->new(
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
            JsonRpc::Notification->new(
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
    my $method  = JsonRpc::MethodName->new(value => 'testMethod');

    my $req_array = JsonRpc::Notification->new(
        jsonrpc => $version,
        method  => $method,
        params  => ['item1', 'item2'],
    );
    is $req_array->params, ['item1', 'item2'], 'params is array';

    my $req_hash = JsonRpc::Notification->new(
        jsonrpc => $version,
        method  => $method,
        params  => {key1 => 'value1', key2 => 'value2'},
    );
    is $req_hash->params, {key1 => 'value1', key2 => 'value2'}, 'params is hash';

    my $req_undef = JsonRpc::Notification->new(
        jsonrpc => $version,
        method  => $method,
        params  => undef,
    );
    is $req_undef->params, undef, 'params is undef';

    # String は拒否
    like(
        dies {
            JsonRpc::Notification->new(
                jsonrpc => $version,
                method  => $method,
                params  => "not an array or hash",
            );
        },
        qr/type constraint|isa/i,
        'rejects string params'
    );
};

done_testing;
