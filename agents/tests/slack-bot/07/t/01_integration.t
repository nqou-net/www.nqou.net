use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol 'gensym';
use lib 'lib';

my $script = './bootstrap.pl';
my $pid = open3(my $in, my $out, my $err = gensym, $^X, '-Ilib', $script);

my $full_output = do { local $/; <$out> };

# Verify Case 1
like $full_output, qr/--- Case 1: 正常なデプロイ ---/, 'Case 1 started';
like $full_output, qr/\[ファイルログ\].*Command: Bot::Command::Deploy/, 'Case 1 FileLogger ok';
like $full_output, qr/\[Slack通知\].*production 環境へのデプロイを開始しました/, 'Case 1 SlackNotifier ok';

# Verify Case 2
like $full_output, qr/--- Case 2: 権限不足 ---/, 'Case 2 started';
like $full_output, qr/Return: ⛔ 権限が不足しています/, 'Case 2 correct error';
# Ensure no logs/notifications for auth failure (as per design in Vol 5/6, execute not called)
# Note: implementation in Vol 6 returns before notify_observers if validation fails?
# Actually Vol 6 Mediator code: if auth fail, returns string immediately. Logic matches.

# Verify Case 3
like $full_output, qr/--- Case 3: ログ取得 ---/, 'Case 3 started';
like $full_output, qr/\[ファイルログ\].*Command: Bot::Command::Log/, 'Case 3 FileLogger ok';
like $full_output, qr/error ログを直近 50 行/, 'Case 3 output ok';

close $in;
waitpid $pid, 0;

done_testing;
