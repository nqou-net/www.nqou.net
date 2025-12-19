use v5.38;
use Test2::V0 -target => 'JsonRpc::Error';
use JsonRpc::ErrorCode qw(:all);

subtest 'constructor with required fields' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32600,
        message => 'Invalid Request',
    );
    
    ok $error, 'Error created with required fields';
    is $error->code, -32600, 'code is correct';
    is $error->message, 'Invalid Request', 'message is correct';
    is $error->data, undef, 'data is undef by default';
};

subtest 'constructor with data field' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32602,
        message => 'Invalid params',
        data    => { field => 'user_id', reason => 'required' },
    );
    
    ok $error, 'Error created with data';
    is $error->data, { field => 'user_id', reason => 'required' }, 'data is hash';
};

subtest 'code must be integer' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => "string", message => 'test');
        },
        qr/type constraint|integer/i,
        'string code is rejected'
    );
};

subtest 'message must be string' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => -32600, message => []);
        },
        qr/type constraint|string/i,
        'numeric message is rejected'
    );
};

subtest 'message cannot be empty' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => -32600, message => '');
        },
        qr/message.*empty/i,
        'empty message is rejected'
    );
};

subtest 'data accepts any type' => sub {
    # String
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => 'string');
    }, 'data accepts string');
    
    # Number
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => 42);
    }, 'data accepts number');
    
    # Array
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => [1, 2, 3]);
    }, 'data accepts array');
    
    # Hash
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => { key => 'val' });
    }, 'data accepts hash');
    
    # undef
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => undef);
    }, 'data accepts undef');
};


subtest 'standard error code constants' => sub {
    is ERROR_PARSE_ERROR,      -32700, 'PARSE_ERROR constant';
    is ERROR_INVALID_REQUEST,  -32600, 'INVALID_REQUEST constant';
    is ERROR_METHOD_NOT_FOUND, -32601, 'METHOD_NOT_FOUND constant';
    is ERROR_INVALID_PARAMS,   -32602, 'INVALID_PARAMS constant';
    is ERROR_INTERNAL_ERROR,   -32603, 'INTERNAL_ERROR constant';
};

subtest 'use constants in Error construction' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );
    
    is $error->code, -32600, 'constant used correctly';
};

done_testing;
