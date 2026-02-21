use v5.36;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Batch::UserSync;

my $sync  = Batch::UserSync->new();
my $count = $sync->sync_all_users();

is($count, 1025, "Fetched and processed all 1025 users one by one");

done_testing();
