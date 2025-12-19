use v5.38;
use Test2::V0;
use lib 'lib';

use JsonRpc::Error;
use JsonRpc::ErrorCode qw(:all);

subtest 'standard error code range boundaries' => sub {
    # 標準エラーの境界値
    subtest 'ERROR_PARSE_ERROR boundary' => sub {
        is ERROR_PARSE_ERROR, -32700, 'parse error code';
    };
    
    subtest 'ERROR_INTERNAL_ERROR boundary' => sub {
        is ERROR_INTERNAL_ERROR, -32603, 'internal error code';
    };
    
    # 標準エラー範囲外もエラーオブジェクトとして作成可能
    # （JSON-RPC仕様はカスタムエラーを許可）
    subtest 'custom error codes are accepted' => sub {
        # カスタムエラー範囲: -32000 〜 -32099
        ok(lives {
            JsonRpc::Error->new(code => -32000, message => 'custom error min');
        }, 'custom error min boundary accepted');
        
        ok(lives {
            JsonRpc::Error->new(code => -32099, message => 'custom error max');
        }, 'custom error max boundary accepted');
        
        # カスタム範囲外も許容（アプリケーション定義）
        ok(lives {
            JsonRpc::Error->new(code => 1, message => 'application error');
        }, 'positive error code accepted');
    };
};

subtest 'integer boundaries' => sub {
    # Perlの整数境界値（32bit/64bit環境依存だが、代表的な値をテスト）
    ok(lives {
        JsonRpc::Error->new(code => -2147483648, message => 'min int32');
    }, 'minimum int32 accepted');
    
    ok(lives {
        JsonRpc::Error->new(code => 2147483647, message => 'max int32');
    }, 'maximum int32 accepted');
    
    ok(lives {
        JsonRpc::Error->new(code => 0, message => 'zero code');
    }, 'zero code accepted');
};

subtest 'message string length boundaries' => sub {
    # 空文字列は拒否される（既存テストで確認済みだが再確認）
    like(
        dies {
            JsonRpc::Error->new(code => -1, message => '');
        },
        qr/empty/i,
        'empty message rejected'
    );
    
    # 1文字は許容
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'X');
    }, '1 character message accepted');
    
    # 非常に長い文字列も許容（JSON-RPC仕様に制限なし）
    subtest 'very long message' => sub {
        my $long_message = 'A' x 10000;  # 10,000文字
        
        my $error = JsonRpc::Error->new(
            code    => -1,
            message => $long_message,
        );
        
        is length($error->message), 10000, 'long message accepted';
    };
    
    # Unicode文字列
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'エラーが発生しました');
    }, 'unicode message accepted');
    
    # 特殊文字
    ok(lives {
        JsonRpc::Error->new(code => -1, message => qq{Error: "invalid"\n});
    }, 'message with special characters accepted');
};

done_testing;
