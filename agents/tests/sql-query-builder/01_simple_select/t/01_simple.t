use v5.36;
use Test::More;
use lib 'lib';

use_ok 'Query';

my $query = Query->new(table => 'users');
is $query->to_sql, 'SELECT * FROM users', 'Simple SELECT query';

done_testing;
