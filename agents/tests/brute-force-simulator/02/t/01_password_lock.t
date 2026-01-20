use v5.36;
use Test::More;
use lib 'lib';

use_ok('PasswordLock');

subtest 'PasswordLock basic tests' => sub {
    my $lock = PasswordLock->new;
    isa_ok($lock, 'PasswordLock');
    
    # Test wrong passwords
    ok(!$lock->unlock('0000'), 'Wrong 4-digit password returns false');
    ok(!$lock->unlock('1234'), 'Another wrong password returns false');
    
    # Test correct password (default is '777')
    ok($lock->unlock('777'), 'Correct password returns true');
};

done_testing();
