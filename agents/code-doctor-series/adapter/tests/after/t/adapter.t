use v5.36;
use Test2::V0;
use lib 'lib';
use LegacyInventoryTool;
use InventoryAdapter;

my $legacy = LegacyInventoryTool->new();
my $adapter = InventoryAdapter->new($legacy);

subtest 'Web API style: fetch_stock' => sub {
    my $res = $adapter->fetch_stock('item_001');
    is $res, { id => 'item_001', stock => 10, status => 'ok' }, 'JSON-like hash response';
};

subtest 'Web API style: change_stock' => sub {
    my $res = $adapter->change_stock('item_001', 20);
    is $res, { id => 'item_001', status => 'ok' }, 'Success response';
    
    my $check = $adapter->fetch_stock('item_001');
    is $check->{stock}, 20, 'Stock actually updated in legacy tool';
};

subtest 'Error handling' => sub {
    my $res = $adapter->fetch_stock('non_existent');
    is $res->{status}, 'error', 'Error status returned';
    is $res->{message}, 'ERROR: NOT_FOUND', 'Original error message preserved';
};

done_testing;
