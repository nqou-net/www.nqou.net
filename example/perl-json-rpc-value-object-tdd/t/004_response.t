use Test2::V0;
use JsonRpc::Response::Success;
use JsonRpc::Response::Error;
use JsonRpc::Error qw(METHOD_NOT_FOUND);

subtest 'Success レスポンス' => sub {
  my $res = JsonRpc::Response::Success->new(
    result => { sum => 42 },
    id     => 1,
  );

  is $res->result, { sum => 42 }, '結果が正しい';
  is $res->id, 1, 'IDが正しい';

  my $hash = $res->to_hash;
  is $hash, {
    jsonrpc => '2.0',
    result  => { sum => 42 },
    id      => 1,
  }, 'ハッシュ表現';
};

subtest 'Error レスポンス' => sub {
  my $error = JsonRpc::Error->new(
    code    => METHOD_NOT_FOUND,
    message => 'Method not found',
  );

  my $res = JsonRpc::Response::Error->new(
    error => $error,
    id    => 1,
  );

  isa_ok $res->error, ['JsonRpc::Error'], 'エラーオブジェクト';
  is $res->id, 1, 'IDが正しい';

  my $hash = $res->to_hash;
  is $hash, {
    jsonrpc => '2.0',
    error   => {
      code    => -32601,
      message => 'Method not found',
    },
    id => 1,
  }, 'ハッシュ表現';
};

subtest 'IDはnullも許可' => sub {
  my $res = JsonRpc::Response::Success->new(
    result => 'ok',
    id     => undef,
  );

  is $res->id, undef, 'nullのID';
};

done_testing;
