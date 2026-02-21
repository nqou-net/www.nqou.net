use v5.36;
use utf8;
use experimental 'signatures';
use Test2::V0;
use lib 'lib';
use Subject::Idol;
use Observer::Fan;

my $idol = Subject::Idol->new('ピュア・バイナリ');

# 様々なチャネルからの購読者（ファン）を作って登録（attach）する
my $gondo_line    = Observer::Fan->new('LINE',    '権藤鉄朗');
my $gondo_discord = Observer::Fan->new('Discord', 'gondo_infra');
my $guild_member  = Observer::Fan->new('Mail',    '名無しファン');

$idol->attach($gondo_line);
$idol->attach($gondo_discord);
$idol->attach($guild_member);

is $gondo_line->get_notifications(), [], "まだ何も通知はない";

# 突然アイドル側からゲリラライブ告知の更新が入る（Pushの起点）
$idol->set_status('guerrilla_live_ticket_open');

# 権藤側は何もしなくても、一斉にPushされて通知が届いている
is $gondo_line->get_notifications(), ["[LINE/権藤鉄朗] ピュア・バイナリ の状態が guerrilla_live_ticket_open になりました！全裸待機します！"], "LINEに通知がPushされている";

is $gondo_discord->get_notifications(), ["[Discord/gondo_infra] ピュア・バイナリ の状態が guerrilla_live_ticket_open になりました！全裸待機します！"], "Discordにも正しくPullなしで届いている";

is $guild_member->get_notifications(), ["[Mail/名無しファン] ピュア・バイナリ の状態が guerrilla_live_ticket_open になりました！全裸待機します！"], "他のファンにも同時にPushで完了している";

done_testing;
