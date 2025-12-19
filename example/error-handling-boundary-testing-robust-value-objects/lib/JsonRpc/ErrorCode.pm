package JsonRpc::ErrorCode;
use v5.38;
use Exporter 'import';

our @EXPORT_OK = qw(
    ERROR_PARSE_ERROR
    ERROR_INVALID_REQUEST
    ERROR_METHOD_NOT_FOUND
    ERROR_INVALID_PARAMS
    ERROR_INTERNAL_ERROR
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

# JSON-RPC 2.0 標準エラーコード
use constant ERROR_PARSE_ERROR      => -32700;
use constant ERROR_INVALID_REQUEST  => -32600;
use constant ERROR_METHOD_NOT_FOUND => -32601;
use constant ERROR_INVALID_PARAMS   => -32602;
use constant ERROR_INTERNAL_ERROR   => -32603;

# カスタムエラーコード範囲: -32000 〜 -32099
# アプリケーション独自のエラーはこの範囲内で定義する

1;
