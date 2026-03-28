use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Bulkhead パターン ===
# 各サービスに独立した隔壁（同時実行枠）を割り当て、
# 一つのサービスの遅延が他サービスに波及しない構造にする。

# --- Bulkhead（隔壁） ---
package Bulkhead {
    use Moo;
    use Types::Standard qw(Int Str ArrayRef);
    use Carp qw(croak);

    has name           => (is => 'ro', isa => Str, required => 1);
    has max_concurrent => (is => 'ro', isa => Int, required => 1);
    has _active_count  => (is => 'rw', isa => Int, default => 0);
    has _log           => (is => 'ro', isa => ArrayRef, default => sub { [] });

    sub execute ($self, $action) {
        if ($self->_active_count >= $self->max_concurrent) {
            push @{$self->_log}, "REJECTED:" . $self->name;
            croak sprintf(
                "Bulkhead '%s' is full (%d/%d): request rejected",
                $self->name, $self->_active_count, $self->max_concurrent,
            );
        }
        $self->_active_count($self->_active_count + 1);
        push @{$self->_log}, "ADMITTED:" . $self->name;
        my $result = eval { $action->() };
        my $err = $@;
        $self->_active_count($self->_active_count - 1);
        push @{$self->_log}, "RELEASED:" . $self->name;
        die $err if $err;
        return $result;
    }

    sub active_count ($self) { $self->_active_count }
    sub log ($self)          { @{$self->_log} }
}

# --- IsolatedServiceRunner（各サービスが独立した Bulkhead を持つ） ---
package IsolatedServiceRunner {
    use Moo;
    use Types::Standard qw(InstanceOf);

    has image_bulkhead => (
        is      => 'ro',
        isa     => InstanceOf['Bulkhead'],
        default => sub { Bulkhead->new(name => 'image', max_concurrent => 2) },
    );
    has order_bulkhead => (
        is      => 'ro',
        isa     => InstanceOf['Bulkhead'],
        default => sub { Bulkhead->new(name => 'order', max_concurrent => 3) },
    );
    has notify_bulkhead => (
        is      => 'ro',
        isa     => InstanceOf['Bulkhead'],
        default => sub { Bulkhead->new(name => 'notify', max_concurrent => 2) },
    );

    sub run_image_processing ($self) {
        return $self->image_bulkhead->execute(sub {
            return 'image_done';
        });
    }

    sub run_order_processing ($self) {
        return $self->order_bulkhead->execute(sub {
            return 'order_done';
        });
    }

    sub run_notification ($self) {
        return $self->notify_bulkhead->execute(sub {
            return 'notify_done';
        });
    }
}

1;
