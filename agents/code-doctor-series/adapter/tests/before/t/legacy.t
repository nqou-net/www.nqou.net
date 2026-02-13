use v5.36;
use Test2::V0;
use lib 'lib';
use LegacyInventoryTool;

my $tool = LegacyInventoryTool->new();

subtest 'get_stock' => sub {
    is $tool->run(['get_stock', 'item_001']), 'STOCK:item_001:10';
    is $tool->run(['get_stock', 'invalid']), 'ERROR: NOT_FOUND';
};

subtest 'update_stock' => sub {
    is $tool->run(['update_stock', 'item_001', 15]), 'SUCCESS:UPDATED:item_001';
    is $tool->run(['get_stock', 'item_001']), 'STOCK:item_001:15';
};

done_testing;
