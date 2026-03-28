use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Shared Resource Pool（共有リソースプールの独占） ===
# 全サービスが単一のコネクションプールを共有し、
# 一つの遅延サービスが全リソースを占有して他サービスも道連れにする。

# --- SharedPool（共有コネクションプール） ---
package SharedPool {
    use Moo;
    use Types::Standard qw(Int ArrayRef);
    use Carp qw(croak);

    has max_size   => (is => 'ro', isa => Int, default => 5);
    has _available => (is => 'rw', isa => Int, lazy => 1, builder => '_build_available');
    has _log       => (is => 'ro', isa => ArrayRef, default => sub { [] });

    sub _build_available ($self) { $self->max_size }

    sub acquire ($self, $label) {
        if ($self->_available <= 0) {
            push @{$self->_log}, "REJECTED:$label";
            croak "Pool exhausted: no connections available for '$label'";
        }
        $self->_available($self->_available - 1);
        push @{$self->_log}, "ACQUIRED:$label";
        return 1;
    }

    sub release ($self, $label) {
        if ($self->_available < $self->max_size) {
            $self->_available($self->_available + 1);
            push @{$self->_log}, "RELEASED:$label";
        }
    }

    sub available ($self) { $self->_available }
    sub log ($self)       { @{$self->_log} }
}

# --- ServiceRunner（全サービスが同じプールを共有） ---
package ServiceRunner {
    use Moo;
    use Types::Standard qw(InstanceOf);

    has pool => (is => 'ro', isa => InstanceOf['SharedPool'], required => 1);

    sub run_image_processing ($self) {
        $self->pool->acquire('image');
        # 画像変換は重い——接続を保持したまま処理
        # （テストでは release を呼ばないことで「占有」を再現）
        return 'image_done';
    }

    sub run_order_processing ($self) {
        $self->pool->acquire('order');
        $self->pool->release('order');
        return 'order_done';
    }

    sub run_notification ($self) {
        $self->pool->acquire('notify');
        $self->pool->release('notify');
        return 'notify_done';
    }
}

1;
