use v5.36;
use Test2::V0;
use lib 'lib';

use Good::File;
use Good::Directory;

my $root = Good::Directory->new(name => 'root');
my $etc  = Good::Directory->new(name => 'etc');
my $conf = Good::File->new(name => 'nginx.conf');
my $home = Good::Directory->new(name => 'home');
my $user = Good::File->new(name => 'user.txt');

# 構築方法は同じ（ここはFactory等でさらに隠蔽可能だが今回はCompositeに集中）
$root->add($etc);
$root->add($home);
$etc->add($conf);
$home->add($user);

# クライアントコード（呼び出し側）が劇的に単純化
# Processorクラスすら不要で、ルート・コンポーネントを叩くだけ
my $logs = $root->backup('/backup');

ok(scalar(@$logs) > 0, 'Backup processed');
like($logs->[0], qr/Creating directory root/, 'Root processed');

# 構造の確認
# note explain $logs;

done_testing;
