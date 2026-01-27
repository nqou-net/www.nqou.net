use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bot::CommandMediator;
use Bot::Command::Deploy;
use Bot::Command::Log;

my $mediator = Bot::CommandMediator->new;
$mediator->register_command(Bot::Command::Deploy->new);
$mediator->register_command(Bot::Command::Log->new);

# Test 1: Deploy with admin role (Success)
my $res = $mediator->dispatch('/deploy production', 'admin');
like $res, qr/production 環境へのデプロイを開始しました/, 'Admin deploy success';

# Test 2: Deploy with guest role (Fail)
$res = $mediator->dispatch('/deploy production', 'guest');
like $res, qr/権限が不足しています/, 'Guest deploy prevented';

# Test 3: Log (No role required)
$res = $mediator->dispatch('/log error', 'guest');
like $res, qr/error ログ/, 'Log command works without role';

# Test 4: Unknown
$res = $mediator->dispatch('/hello', 'admin');
is $res, "不明なコマンドです。", 'Unknown command handling';

done_testing;
