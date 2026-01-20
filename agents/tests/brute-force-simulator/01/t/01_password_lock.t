use v5.36;
use Test::More;
use lib 'lib';

use_ok('PasswordLock');

subtest 'PasswordLock basic tests' => sub {
    my $lock = PasswordLock->new;
    isa_ok($lock, 'PasswordLock');
    
    # Test wrong passwords
    ok(!$lock->unlock('000'), 'Wrong password returns false');
    ok(!$lock->unlock('123'), 'Another wrong password returns false');
    ok(!$lock->unlock('999'), 'Yet another wrong password returns false');
    
    # Test correct password
    ok($lock->unlock('777'), 'Correct password returns true');
};

subtest 'Custom secret' => sub {
    my $lock = PasswordLock->new(_secret => '123');
    ok(!$lock->unlock('777'), 'Default password does not work');
    ok($lock->unlock('123'), 'Custom password works');
};

done_testing();
