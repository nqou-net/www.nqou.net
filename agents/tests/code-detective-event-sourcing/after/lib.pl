use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Event Sourcing ===
# 状態を上書きせず、「出来事（イベント）」を積み重ねる。
# 現在の在庫は全イベントのリプレイで算出。
# 任意の時点の在庫も、イベントをフィルタして復元できる。

package StockEvent {
    use Moo;
    use Types::Standard qw(Str Int);

    has type        => (is => 'ro', isa => Str, required => 1);  # 'added' | 'reduced'
    has quantity    => (is => 'ro', isa => Int, required => 1);
    has occurred_at => (is => 'ro', isa => Int, required => 1);
}

package Item {
    use Moo;
    use Types::Standard qw(Str ArrayRef);

    has id     => (is => 'ro', isa => Str, required => 1);
    has name   => (is => 'ro', isa => Str, required => 1);
    has events => (is => 'ro', isa => ArrayRef, default => sub { [] });

    # 現在の在庫を全イベントのリプレイで算出
    sub stock ($self, $upto = undef) {
        my $total = 0;
        for my $e (@{ $self->events }) {
            last if defined $upto && $e->occurred_at > $upto;
            $total += $e->quantity if $e->type eq 'added';
            $total -= $e->quantity if $e->type eq 'reduced';
        }
        return $total;
    }

    sub add_stock ($self, $qty) {
        push @{ $self->events }, StockEvent->new(
            type        => 'added',
            quantity    => $qty,
            occurred_at => time(),
        );
        return $self;
    }

    sub reduce_stock ($self, $qty) {
        die "在庫不足\n" if $self->stock < $qty;
        push @{ $self->events }, StockEvent->new(
            type        => 'reduced',
            quantity    => $qty,
            occurred_at => time(),
        );
        return $self;
    }

    # 全イベント履歴を返す
    sub history ($self) {
        return @{ $self->events };
    }
}

1;
