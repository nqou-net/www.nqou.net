use strict;
use warnings;
use Test::More;
use utf8;

require './spaghetti_bot.pl';

# Test 1: Production deploy without admin role
my $res = handle_message('/deploy production', 'guest');
like $res, qr/管理者権限が必要です/, 'Permission check works';

# Test 2: Production deploy with admin role
$res = handle_message('/deploy production', 'admin');
like $res, qr/production 環境へのデプロイを開始しました/, 'Admin deploy works';

# Test 3: SQL injection prevention
$res = handle_message('/sql "DROP TABLE users"', 'admin');
like $res, qr/破壊的なクエリ/, 'SQL injection check works';

# Test 4: Default options
$res = handle_message('/log error', 'admin');
like $res, qr/直近 10 行/, 'Default option works';

done_testing;
