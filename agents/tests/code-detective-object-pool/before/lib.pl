use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Excessive Object Creation（高コストオブジェクトの使い捨て） ===
# DB接続をレコードごとに生成・切断し、負荷増大時にリソース枯渇を起こす。

# --- DatabaseConnection（DB接続のシミュレーション） ---
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

# --- BatchProcessor（アンチパターン: 毎回接続を生成・切断） ---
package BatchProcessor {
    use Moo;

    sub process_records ($self, $records) {
        my @results;
        for my $record (@$records) {
            my $conn = DatabaseConnection->new;
            $conn->connect;

            my $result = $conn->execute(
                'SELECT * FROM sales WHERE id = ?', $record->{id}
            );
            push @results, $result;

            $conn->disconnect;
        }
        return \@results;
    }
}

1;
