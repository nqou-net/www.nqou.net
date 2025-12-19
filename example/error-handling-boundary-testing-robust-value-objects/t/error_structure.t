use v5.38;
use Test2::V0;
use lib 'lib';

use JsonRpc::Error;

subtest 'data field structure validation' => sub {
    subtest 'data as hash structure' => sub {
        my $error = JsonRpc::Error->new(
            code    => -32602,
            message => 'Invalid params',
            data    => {
                field  => 'user_id',
                reason => 'required',
                index  => 0,
            },
        );

        # hashによる構造検証
        is $error->data, hash {
            field 'field'  => 'user_id';
            field 'reason' => 'required';
            field 'index'  => 0;
            end;    # 他のフィールドが存在しないことを確認
        }, 'data hash structure is correct';
    };

    subtest 'data as array structure' => sub {
        my $error = JsonRpc::Error->new(
            code    => -32602,
            message => 'Multiple errors',
            data    => [{field => 'name', reason => 'required'}, {field => 'email', reason => 'invalid format'},],
        );

        # arrayによる構造検証
        is $error->data, array {
            item hash {
                field 'field'  => 'name';
                field 'reason' => 'required';
                end;
            };
            item hash {
                field 'field'  => 'email';
                field 'reason' => 'invalid format';
                end;
            };
            end;
        }, 'data array structure is correct';
    };
};

subtest 'flexible validation with match' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32603,
        message => 'Internal error: database connection failed',
        data    => {timestamp => 1734326400, retry_after => 60},
    );

    # matchによる柔軟な検証
    is $error, object {
        prop blessed => 'JsonRpc::Error';

        call code => -32603;

        # messageは特定のパターンに一致
        call message => match qr/^Internal error:/;

        # dataの構造を柔軟に検証
        call data => hash {
            field 'timestamp'   => match qr/^\d+$/;    # 数値
            field 'retry_after' => D();                # 定義されている（値は問わない）
            end;
        };
    }, 'error object matches expected structure';
};

subtest 'validate with number ranges' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32050,           # カスタムエラー範囲内
        message => 'Server error',
    );

    # codeが特定範囲内にあることを検証
    is $error->code, validator(sub { return $_ >= -32099 && $_ <= -32000 }), 'code is within custom error range';
};

done_testing;
