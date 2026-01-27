#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

# クラスのロード
use Bot::CommandMediator;
use Bot::Command::Deploy;
use Bot::Command::Log;
use Bot::Command::Help;
use Bot::Observer::SlackNotifier;
use Bot::Observer::FileLogger;

# 1. Mediator（指令塔）の生成
my $mediator = Bot::CommandMediator->new;

# 2. Command（手足）の登録
$mediator->register_command(Bot::Command::Deploy->new);
$mediator->register_command(Bot::Command::Log->new);
$mediator->register_command(Bot::Command::Help->new(mediator => $mediator));

# 3. Observer（監視者）の登録
$mediator->add_observer(Bot::Observer::FileLogger->new);
# 実際はここに本物のSlack APIトークンなどを渡す
$mediator->add_observer(Bot::Observer::SlackNotifier->new);

# --- ここまでが初期化 ---

# 4. 実行シミュレーション（Webhookからの入力を想定）
print "--- Case 1: 正常なデプロイ ---\n";
my $result1 = $mediator->dispatch("/deploy production", "admin", "nobu");
print "Return: $result1\n\n";

print "--- Case 2: 権限不足 ---\n";
my $result2 = $mediator->dispatch("/deploy production", "guest", "unknown_user");
print "Return: $result2\n\n";

print "--- Case 3: ログ取得 ---\n";
my $result3 = $mediator->dispatch("/log error --lines 50", "admin", "nobu");
print "Return: $result3\n";
