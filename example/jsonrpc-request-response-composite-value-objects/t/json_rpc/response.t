use v5.38;
use Test2::V0 -target => 'JsonRpc::Response';

use JsonRpc::Version;

subtest 'constructor with all required fields' => sub {
    my $res = JsonRpc::Response->new(
        jsonrpc => JsonRpc::Version->new,
        result  => { name => 'Alice', age => 30 },
        id      => 'req-001',
    );
    
    ok $res, 'Response created';
    isa_ok $res->jsonrpc, ['JsonRpc::Version'], 'version';
    is $res->result, { name => 'Alice', age => 30 }, 'result is hash';
    is $res->id, 'req-001', 'id is string';
};

subtest 'result accepts any type' => sub {
    my $version = JsonRpc::Version->new;
    
    # 文字列
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => 'success', id => 1);
    }, 'result accepts string');
    
    # 数値
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => 42, id => 2);
    }, 'result accepts number');
    
    # 配列
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => [1, 2, 3], id => 3);
    }, 'result accepts array');
    
    # ハッシュ
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => { ok => 1 }, id => 4);
    }, 'result accepts hash');
    
    # null/undef
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => undef, id => 5);
    }, 'result accepts undef');
};

subtest 'id is required' => sub {
    like(dies {
        JsonRpc::Response->new(
            jsonrpc => JsonRpc::Version->new,
            result  => 'ok',
        );
    }, qr/required|missing/i, 'id is required');
};

subtest 'from_hash factory method' => sub {
    my $res = JsonRpc::Response->from_hash({
        jsonrpc => '2.0',
        result  => { status => 'ok' },
        id      => 'test-id',
    });
    
    isa_ok $res,['JsonRpc::Response'], 'Response created from hash';
    is $res->result, { status => 'ok' }, 'result is correct';
    is $res->id, 'test-id', 'id is correct';
};

subtest 'to_hash converts back to hash' => sub {
    my $res = JsonRpc::Response->from_hash({
        jsonrpc => '2.0',
        result  => [1, 2, 3],
        id      => 999,
    });
    
    is $res->to_hash, {
        jsonrpc => '2.0',
        result  => [1, 2, 3],
        id      => 999,
    }, 'to_hash produces correct hash';
};

done_testing;
