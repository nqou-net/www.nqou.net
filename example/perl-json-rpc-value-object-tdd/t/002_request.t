use Test2::V0;
use JsonRpc::Request;

subtest '正しいRequestの構築' => sub {
  my $req = JsonRpc::Request->new(
    method => 'subtract',
    params => [ 42, 23 ],
    id     => 1,
  );

  ok $req, 'オブジェクトが作成できる';
  is $req->method, 'subtract', 'メソッド名が正しい';
  is $req->params, [ 42, 23 ], 'パラメータが正しい';
  is $req->id, 1, 'IDが正しい';
  isa_ok $req->version,  ['JsonRpc::Version'];
};

subtest 'パラメータは省略可能' => sub {
  my $req = JsonRpc::Request->new(
    method => 'ping',
    id     => 2,
  );

  is $req->params, undef, 'paramsはundef';
};

subtest 'メソッド名は必須' => sub {
  like(
    dies {JsonRpc::Request->new(id => 1)},
      qr/required/i,
      'methodなしは失敗'
  );
};

subtest 'メソッド名の制約' => sub {
  like(
    dies { JsonRpc::Request->new(method => 'rpc.reserved', id => 1) },
      qr/must not start with/,
      'rpc.始まりは拒否'
  );
};

subtest 'IDは必須（Notificationと区別）' => sub {
  like(
    dies {JsonRpc::Request->new(method => 'test')},
      qr/required/i,
      'idなしは失敗'
  );
};

subtest 'IDの型（文字列・数値・null）' => sub {
  ok scalar JsonRpc::Request->new(method => 'test', id => 1), '数値ID';
  ok scalar JsonRpc::Request->new(method => 'test', id => 'abc'), '文字列ID';
  ok scalar JsonRpc::Request->new(method => 'test', id => undef), 'null ID';
};

subtest 'ハッシュへの変換' => sub {
  my $req = JsonRpc::Request->new(
    method => 'add',
    params => { a => 1, b => 2 },
    id     => 3,
  );

  my $hash = $req->to_hash;
  is $hash, {
    jsonrpc => '2.0',
    method  => 'add',
    params  => { a => 1, b => 2 },
    id      => 3,
  }, 'ハッシュ表現が正しい';
};

done_testing;
