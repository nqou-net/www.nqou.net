use v5.36;
use Test2::V0;
use lib 'lib';

use Bad::File;
use Bad::Directory;
use Bad::Processor;

my $root = Bad::Directory->new(name => 'root');
my $etc  = Bad::Directory->new(name => 'etc');
my $conf = Bad::File->new(name => 'nginx.conf');
my $home = Bad::Directory->new(name => 'home');
my $user = Bad::File->new(name => 'user.txt');

$root->add($etc);
$root->add($home);
$etc->add($conf);
$home->add($user);

my $processor = Bad::Processor->new();
my $logs      = $processor->process_backup($root, '/backup');

ok(scalar(@$logs) > 0, 'Backup processed');
like($logs->[0], qr/Creating directory root/, 'Root processed');

# 再帰的構造のチェック
# Bad codeでも動くことは動く

done_testing;
