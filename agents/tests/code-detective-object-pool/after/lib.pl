use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Object Pool パターン ===
# 高コストなオブジェクトをプールに保持し、使い終わったら返却して再利用する。

# --- DatabaseConnection（Before と同じ） ---
package DatabaseConnection {
    use Moo;
    use Types::Standard qw(Str Int Bool);

    has host     => (is => 'ro', isa => Str, default => 'localhost');
    has port     => (is => 'ro', isa => Int, default => 5432);
    has database => (is => 'ro', isa => Str, default => 'sales');
    has _connected => (is => 'rw', isa => Bool, default => 0);

    our $TOTAL_CREATED = 0;

    sub connect ($self) {
        $TOTAL_CREATED++;
        $self->_connected(1);
        return $self;
    }

    sub disconnect ($self) {
        $self->_connected(0);
        return;
    }

    sub execute ($self, $query, @params) {
        die "Not connected" unless $self->_connected;
        return { query => $query, params => \@params, status => 'ok' };
    }

    sub is_connected ($self) { $self->_connected }

    sub reset_counter { $TOTAL_CREATED = 0 }
}

# --- ConnectionPool（Object Pool パターン） ---
package ConnectionPool {
    use Moo;
    use Types::Standard qw(Int ArrayRef CodeRef);
    use Carp qw(croak);

    has max_size   => (is => 'ro', isa => Int, default => 5);
    has factory    => (is => 'ro', isa => CodeRef, required => 1);
    has _available => (is => 'ro', isa => ArrayRef, default => sub { [] });
    has _in_use    => (is => 'ro', isa => ArrayRef, default => sub { [] });

    sub acquire ($self) {
        my $obj;
        if (@{ $self->_available }) {
            $obj = pop @{ $self->_available };
        }
        elsif ($self->size < $self->max_size) {
            $obj = $self->factory->();
        }
        else {
            croak "Pool exhausted: all @{[$self->max_size]} objects in use";
        }
        push @{ $self->_in_use }, $obj;
        return $obj;
    }

    sub release ($self, $obj) {
        my @remaining;
        my $found = 0;
        for my $item (@{ $self->_in_use }) {
            if (!$found && $item == $obj) {
                $found = 1;
                next;
            }
            push @remaining, $item;
        }
        croak "Object not found in pool" unless $found;
        @{ $self->_in_use } = @remaining;
        push @{ $self->_available }, $obj;
        return;
    }

    sub size ($self) {
        return scalar(@{ $self->_available }) + scalar(@{ $self->_in_use });
    }

    sub available_count ($self) {
        return scalar @{ $self->_available };
    }

    sub in_use_count ($self) {
        return scalar @{ $self->_in_use };
    }
}

# --- BatchProcessor（Object Pool を使用） ---
package BatchProcessor {
    use Moo;

    has pool => (is => 'ro', required => 1);

    sub process_records ($self, $records) {
        my @results;
        for my $record (@$records) {
            my $conn = $self->pool->acquire;

            my $result = $conn->execute(
                'SELECT * FROM sales WHERE id = ?', $record->{id}
            );
            push @results, $result;

            $self->pool->release($conn);
        }
        return \@results;
    }
}

1;
