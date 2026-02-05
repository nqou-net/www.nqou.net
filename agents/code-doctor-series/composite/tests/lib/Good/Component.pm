package Good::Component;
use v5.36;
use Role::Tiny;

# 共通インターフェース
requires 'backup';
requires 'name';

1;
