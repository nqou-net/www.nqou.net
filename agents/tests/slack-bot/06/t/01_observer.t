use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bot::CommandMediator;
use Bot::Command::Deploy;
use Bot::Observer::SlackNotifier;

my $mediator = Bot::CommandMediator->new;
$mediator->register_command(Bot::Command::Deploy->new);
$mediator->add_observer(Bot::Observer::SlackNotifier->new);

# Capture stdout to verify notification
my $stdout = '';
open my $handle, '>', \$stdout;
select $handle;

my $res = $mediator->dispatch('/deploy production', 'admin', 'nobu');

select STDOUT;
close $handle;

like $res, qr/production 環境へのデプロイを開始しました/, 'Command executed';
like $stdout, qr/\[Slack通知\]/, 'Observer notified';
like $stdout, qr/production 環境へのデプロイを開始しました/, 'Observer received message';

done_testing;
