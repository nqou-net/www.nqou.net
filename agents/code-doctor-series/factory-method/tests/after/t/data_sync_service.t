#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';
use DataSyncService;

subtest 'sync_data to salesforce' => sub {
    my $service = DataSyncService->new;
    ok($service->sync_data('salesforce', {name => 'Test Lead'}), 'salesforce sync OK');
};

subtest 'sync_data to kintone' => sub {
    my $service = DataSyncService->new;
    ok($service->sync_data('kintone', {record_id => 1, value => 'test'}), 'kintone sync OK');
};

subtest 'sync_data to slack' => sub {
    my $service = DataSyncService->new;
    ok($service->sync_data('slack', {message => 'Hello!'}), 'slack sync OK');
};

subtest 'unknown target dies' => sub {
    my $service = DataSyncService->new;
    eval { $service->sync_data('unknown', {}) };
    like($@, qr/Unknown target/, 'unknown target throws error');
};

done_testing;
