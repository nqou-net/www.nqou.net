use v5.36;
use utf8;
use experimental 'signatures';
use Test2::V0;
use lib 'lib';
use SubjectPoller;

my $api    = FakeIdolApi->new();
my $poller = SubjectPoller->new($api);

# 何も起きていない平和な時間帯。権藤は1秒ごとに叩く（つもり）
$poller->check_once();
$poller->check_once();
$poller->check_once();
$poller->check_once();

is $poller->{request_count},     4,  "状態が変わっていなくても無駄に4回リクエストしている（愛ゆえのDDoS）";
is $poller->get_notifications(), [], "通知はまだない";

# 突然のゲリラライブ告知！
$api->update_status('guerrilla_live_ticket_open');

# 次のポーリング処理で検知される
$poller->check_once();

is $poller->{request_count}, 5, "さらにリクエストが発生";
is $poller->get_notifications(),
    [
    "[LINE連携] ピュア・バイナリ: guerrilla_live_ticket_open",
    "[Discord Bot] \@everyone 状態更新: guerrilla_live_ticket_open",
    "[パトランプ] 回転開始！ (guerrilla_live_ticket_open)",
    ],
    "ハードコードされた通知先に一斉に飛ぶ";

done_testing;
