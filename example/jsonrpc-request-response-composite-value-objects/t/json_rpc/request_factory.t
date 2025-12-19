use v5.38;
use Test2::V0 -target => 'JsonRpc::RequestFactory';

subtest 'constructor with required fields only' => sub {
    subtest 'from_hash creates JsonRpc::Request' => sub {
        my $req = JsonRpc::RequestFactory->from_hash(
            {
                jsonrpc => '2.0',
                method  => 'createUser',
                params  => {name => 'Bob'},
                id      => 123,
            }
        );

        isa_ok $req,          ['JsonRpc::Request'];
        isa_ok $req->jsonrpc, ['JsonRpc::Version'];
        isa_ok $req->method,  ['JsonRpc::MethodName'];
        is $req->method->value,           'createUser', 'method value is createUser';
        is $req->params, {name => 'Bob'}, 'params is hash';
        is $req->id,                      123, 'id is integer';
    };

    subtest 'from_hash creates JsonRpc::Notification' => sub {
        my $req = JsonRpc::RequestFactory->from_hash(
            {
                jsonrpc => '2.0',
                method  => 'notifyEvent',
                params  => ['event1', 'event2'],
            }
        );

        isa_ok $req,          ['JsonRpc::Notification'];
        isa_ok $req->jsonrpc, ['JsonRpc::Version'];
        isa_ok $req->method,  ['JsonRpc::MethodName'];
        is $req->method->value, 'notifyEvent',        'method value is notifyEvent';
        is $req->params,        ['event1', 'event2'], 'params is array';
    };
};

done_testing;
