use Test2::V0;
use JsonRpc::Error;

subtest '標準エラーコード' => sub {
  my $error = JsonRpc::Error->new(
    code    => -32600,
    message => 'Invalid Request',
  );

  is $error->code, -32600, 'コードが正しい';
  is $error->message, 'Invalid Request', 'メッセージが正しい';
};

subtest 'カスタムエラーコード（-32000〜-32099）' => sub {
  my $error = JsonRpc::Error->new(
    code    => -32000,
    message => 'Server error',
    data    => { detail => 'Database connection failed' },
  );

  is $error->code, -32000, 'カスタムコード';
  is $error->data->{detail}, 'Database connection failed', 'data付き';
};

subtest '予約範囲外のコードは拒否' => sub {
  like(
    dies { JsonRpc::Error->new(code => 32768, message => 'test') },
      qr/Invalid error code/,
      '予約範囲外は拒否'
  );
};

subtest '標準エラーの定数' => sub {
  is(JsonRpc::Error::PARSE_ERROR, -32700, 'Parse error');
  is(JsonRpc::Error::INVALID_REQUEST, -32600, 'Invalid Request');
  is(JsonRpc::Error::METHOD_NOT_FOUND, -32601, 'Method not found');
  is(JsonRpc::Error::INVALID_PARAMS, -32602, 'Invalid params');
  is(JsonRpc::Error::INTERNAL_ERROR, -32603, 'Internal error');
};

subtest 'ハッシュへの変換' => sub {
  my $error = JsonRpc::Error->new(
    code    => -32601,
    message => 'Method not found',
  );

  is $error->to_hash, {
    code    => -32601,
    message => 'Method not found',
  }, 'ハッシュ表現';
};

done_testing;
