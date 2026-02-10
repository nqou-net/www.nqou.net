package Role::SyncClient;
use v5.36;
use Moo::Role;

# すべてのSyncClientが実装すべきインターフェース
requires 'sync';

1;
