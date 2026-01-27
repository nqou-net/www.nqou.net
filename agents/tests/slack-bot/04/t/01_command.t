use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bot::Command::Deploy;
use Bot::Command::Log;

my @commands = (
    Bot::Command::Deploy->new,
    Bot::Command::Log->new,
);

sub handle_message {
    my ($text) = @_;
    for my $cmd (@commands) {
        if (my $args = $cmd->match($text)) {
            return $cmd->execute($args);
        }
    }
    return "不明なコマンドです。";
}

# Test 1: Deploy
my $res = handle_message('/deploy production');
like $res, qr/production 環境へのデプロイを開始しました/, 'Deploy command works';

# Test 2: Deploy with force
$res = handle_message('/deploy staging --force');
like $res, qr/staging 環境へのデプロイを開始しました\(強制\)/, 'Deploy force works';

# Test 3: Log
$res = handle_message('/log error');
like $res, qr/error ログを直近 10 行/, 'Log default works';

# Test 4: Log with lines
$res = handle_message('/log access --lines 50');
like $res, qr/access ログを直近 50 行/, 'Log lines works';

# Test 5: Unknown
$res = handle_message('/hello');
is $res, "不明なコマンドです。", 'Unknown command works';

done_testing;
