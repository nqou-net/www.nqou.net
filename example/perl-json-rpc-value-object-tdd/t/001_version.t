# t/001_version.t
use Test2::V0;

# テスト対象をロード（まだ存在しない）
use JsonRpc::Version;

subtest 'バージョン2.0を受け入れる' => sub {
  my $version = JsonRpc::Version->new('2.0');
  ok $version, 'オブジェクトが作成できる';
  is $version->value, '2.0', '値が正しい';
};

subtest '不正なバージョンを拒否する' => sub {
  like(
    dies {JsonRpc::Version->new('1.0')},
      qr/Invalid version/,
      '1.0は拒否される'
  );

  like(
    dies {JsonRpc::Version->new('3.0')},
      qr/Invalid version/,
      '3.0も拒否される'
  );
};

subtest '等価性の判定' => sub {
  my $v1 = JsonRpc::Version->new('2.0');
  my $v2 = JsonRpc::Version->new('2.0');

  ok $v1->equals($v2), '同じ値なら等しい';
  isnt "$v1", "$v2", 'オブジェクトは別物';
};

done_testing;
