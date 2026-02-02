use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use lib 'agents/tests/pattern-dna-singleton/lib';

use_ok('DBManager_Before');
use_ok('DBManager_After');

subtest 'Symptoms: Infinite Instance Proliferation' => sub {
    my $conn1 = DBManager_Before->new();
    my $conn2 = DBManager_Before->new();

    isnt(refaddr($conn1),         refaddr($conn2),         'Different instances created');
    isnt($conn1->{connection_id}, $conn2->{connection_id}, 'Connection IDs are different');
};

subtest 'Treatment: Singleton Pattern' => sub {
    DBManager_After->_reset();    # Ensure clean state

    my $conn1 = DBManager_After->instance();
    my $conn2 = DBManager_After->instance();

    is(refaddr($conn1),         refaddr($conn2),         'Same instance returned');
    is($conn1->{connection_id}, $conn2->{connection_id}, 'Connection IDs are identical');

    # Check functionality
    like($conn1->query('SELECT 1'), qr/Result for 'SELECT 1'/, 'Query method works');

    # Direct new call should also return same instance
    my $conn3 = DBManager_After->new();
    is(refaddr($conn1), refaddr($conn3), 'new() also returns the same instance');
};

done_testing();
