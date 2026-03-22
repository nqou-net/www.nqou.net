use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Mutable State / Lost History ===
# 在庫管理システム。stock を rw で直接上書きするため、
# 過去の履歴が一切残らない。「今いくつあるか」しか分からない。

package Item {
    use Moo;

    has id    => (is => 'ro', required => 1);
    has name  => (is => 'ro', required => 1);
    has stock => (is => 'rw', default => 0);  # 上書き可能な状態

    sub add_stock ($self, $qty) {
        $self->stock($self->stock + $qty);
        return $self;
    }

    sub reduce_stock ($self, $qty) {
        die "在庫不足\n" if $self->stock < $qty;
        $self->stock($self->stock - $qty);
        return $self;
    }

    # history() メソッドは存在しない。過去は消えている。
}

1;
