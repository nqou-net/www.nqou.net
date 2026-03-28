use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Cascading Failure（障害時の無限リトライ） ===
# 外部API障害時にリトライを繰り返し、呼び出し側もリソースを使い果たして共倒れする。

# --- ExternalService（外部APIのシミュレーション） ---
package ExternalService {
    use Moo;
    use Types::Standard qw(Bool);

    has is_healthy => (is => 'rw', isa => Bool, default => 1);

    our $TOTAL_CALLS = 0;

    sub request ($self, $params) {
        $TOTAL_CALLS++;
        die "Service unavailable" unless $self->is_healthy;
        return { status => 'ok', data => $params };
    }

    sub reset_counter { $TOTAL_CALLS = 0 }
}

# --- ExternalApiClient（アンチパターン: 障害時もリトライし続ける） ---
package ExternalApiClient {
    use Moo;
    use Types::Standard qw(Int Object);

    has service     => (is => 'ro', isa => Object, required => 1);
    has max_retries => (is => 'ro', isa => Int, default => 3);

    sub call ($self, $params) {
        my $attempts = 0;
        my $last_error;
        while ($attempts < $self->max_retries) {
            $attempts++;
            my $result = eval { $self->service->request($params) };
            if ($@) {
                $last_error = $@;
                next;
            }
            return $result;
        }
        die "API call failed after $attempts attempts: $last_error";
    }
}

1;
