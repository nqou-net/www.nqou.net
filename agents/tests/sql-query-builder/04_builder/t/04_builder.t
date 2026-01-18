use v5.36;
use Test::More;
use lib 'lib';
use_ok 'QueryBuilder';

# Fluent Interfaceのテスト
my $builder = QueryBuilder->new
    ->from('users')
    ->select('id', 'name')
    ->where('status', 'active')
    ->order_by('created_at', 'DESC')
    ->limit(10);

is $builder->build, 
   "SELECT id, name FROM users WHERE status = 'active' ORDER BY created_at DESC LIMIT 10",
   'Generates valid SQL with fluent interface';

# まだ脆弱性があることを確認（リマインダー）
subtest 'Still vulnerable' => sub {
    my $bad_builder = QueryBuilder->new
        ->from('users')
        ->where('name', "' OR '1'='1");
        
    like $bad_builder->build, qr/name = '' OR '1'='1'/, 'Vulnerability persists';
};

done_testing;
