use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bot::CommandMediator;
use Bot::Command::Sleep;
use Bot::Command::Die;
use Bot::Observer::ErrorHandler;

my $mediator = Bot::CommandMediator->new;
$mediator->register_command(Bot::Command::Sleep->new);
$mediator->register_command(Bot::Command::Die->new);
$mediator->add_observer(Bot::Observer::ErrorHandler->new);

# Test 1: Timeout
my $start = time;
my $res = $mediator->dispatch('/sleep', 'admin', 'user');
my $duration = time - $start;

like $res, qr/タイムアウト/, 'Timeout handled correctly';
ok $duration < 4, 'Timeout actually stopped execution early';

# Test 2: Error Handling
# Capture stdout for Observer output
my $stdout = '';
open my $handle, '>', \$stdout;
select $handle;

$res = $mediator->dispatch('/die', 'admin', 'user');

select STDOUT;
close $handle;

like $res, qr/エラーが発生しました/, 'Exception handled correctly';
like $stdout, qr/\[DEV RECOVERY\] Error caught: Intentional Check/, 'ErrorHandler observer notified';

done_testing;
