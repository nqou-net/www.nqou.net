use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol 'gensym';

my $script = './simple_bot.pl';
my $pid = open3(my $in, my $out, my $err = gensym, $^X, $script);

# Test 1: Status command
print $in "/status\n";
my $output = <$out>;
chomp $output;
like $output, qr/オールグリーン/, 'Status command works';

# Test 2: Deploy command
print $in "/deploy production\n";
$output = <$out>;
chomp $output;
like $output, qr/production 環境へのデプロイを開始しました/, 'Deploy command works';

# Test 3: Invalid deploy (validation)
print $in "/deploy invalid_env\n";
$output = <$out>;
chomp $output;
like $output, qr/エラー: 指定可能な環境は/, 'Validation works';

# Test 4: Unknown command
print $in "/unknown\n";
$output = <$out>;
chomp $output;
like $output, qr/不明なコマンドです/, 'Unknown command handling';

close $in;
waitpid $pid, 0;

done_testing;
