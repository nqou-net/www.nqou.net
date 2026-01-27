use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol 'gensym';
use lib 'lib';

# Verify file existence
ok -f 'app.psgi', 'app.psgi exists';
ok -f 'bootstrap.pl', 'bootstrap.pl exists';
ok -f 'lib/Bot/CommandMediator.pm', 'Mediator exists';
ok -f 'lib/Bot/Command/Role.pm', 'Command Role exists';
ok -f 'lib/Bot/Command/Deploy.pm', 'Command Deploy exists';
ok -f 'lib/Bot/Command/Log.pm', 'Command Log exists';
ok -f 'lib/Bot/Command/Help.pm', 'Command Help exists';
ok -f 'lib/Bot/Observer/Role.pm', 'Observer Role exists';
ok -f 'lib/Bot/Observer/SlackNotifier.pm', 'Observer SlackNotifier exists';
ok -f 'lib/Bot/Observer/FileLogger.pm', 'Observer FileLogger exists';
ok -f 'lib/Bot/Observer/ErrorHandler.pm', 'Observer ErrorHandler exists';

# Run bootstrap.pl which integrates everything
my $script = './bootstrap.pl';
my $pid = open3(my $in, my $out, my $err = gensym, $^X, '-Ilib', $script);

my $full_output = do { local $/; <$out> };

like $full_output, qr/--- Case 1: 正常なデプロイ ---/, 'Integration Case 1 ok';
like $full_output, qr/--- Case 2: 権限不足 ---/, 'Integration Case 2 ok';
like $full_output, qr/--- Case 3: ログ取得 ---/, 'Integration Case 3 ok';

close $in;
waitpid $pid, 0;

done_testing;
