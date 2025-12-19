use v5.38;
use Test2::V0 -target => 'JsonRpc::ErrorResponse';
use JsonRpc::Version;
use JsonRpc::Error;
use JsonRpc::ErrorCode qw(:all);

subtest 'constructor with error field' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );
    
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => $error,
        id      => 'req-001',
    );
    
    ok $res, 'ErrorResponse created';
    isa_ok $res->error, 'JsonRpc::Error';
    is $res->id, 'req-001', 'id is correct';
};

subtest 'error field is required' => sub {
    like(
        dies {
            JsonRpc::ErrorResponse->new(
                jsonrpc => JsonRpc::Version->new(value => '2.0'),
                id      => 'test',
            );
        },
        qr/required|missing/i,
        'error field is required'
    );
};

subtest 'result field must not exist in ErrorResponse' => sub {
    # ErrorResponseはerrorのみを持ち、resultは存在しない
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => JsonRpc::Error->new(code => -1, message => 'error'),
        id      => 'test',
    );
    
    # resultメソッドが存在しないことを確認
    ok !$res->can('result'), 'ErrorResponse does not have result method';
};

subtest 'id can be null for parse errors' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_PARSE_ERROR,
        message => 'Parse error',
    );
    
    # idがnullの場合（Perlではundef）
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => $error,
        id      => undef,
    );
    
    is $res->id, undef, 'id is undef for parse error';
};

subtest 'from_hash with null id' => sub {
    my $res = JsonRpc::ErrorResponse->from_hash({
        jsonrpc => '2.0',
        error   => {
            code    => ERROR_PARSE_ERROR,
            message => 'Parse error',
        },
        id => undef,  # JSONではnull
    });
    
    is $res->id, undef, 'null id handled correctly';
};

subtest 'from_hash rejects result field' => sub {
    # errorとresultの両方がある場合は拒否
    like(
        dies {
            JsonRpc::ErrorResponse->from_hash({
                jsonrpc => '2.0',
                error   => { code => -1, message => 'error' },
                result  => 'should not exist',
                id      => 1,
            });
        },
        qr/must not have.*result/i,
        'result field is rejected in ErrorResponse'
    );
};


done_testing;
