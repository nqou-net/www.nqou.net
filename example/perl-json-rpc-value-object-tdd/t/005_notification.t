use Test2::V0;
use JsonRpc::Notification;

subtest '正しいNotificationの構築' => sub {
  my $notif = JsonRpc::Notification->new(
    method => 'notify_user',
    params => { user_id => 123, message => 'Hello' },
  );

  ok $notif, 'オブジェクトが作成できる';
  is $notif->method, 'notify_user', 'メソッド名';
  is $notif->params, { user_id => 123, message => 'Hello' }, 'パラメータ';
  ok !$notif->can('id'), 'IDメソッドは存在しない';
};

subtest 'パラメータは省略可能' => sub {
  my $notif = JsonRpc::Notification->new(
    method => 'ping',
  );

  is $notif->params, undef, 'paramsなし';
};

subtest 'ハッシュへの変換' => sub {
  my $notif = JsonRpc::Notification->new(
    method => 'update',
    params => [1, 2, 3],
  );

  is $notif->to_hash, {
    jsonrpc => '2.0',
    method  => 'update',
    params  => [1, 2, 3],
  }, 'IDフィールドがない';
};

done_testing;
