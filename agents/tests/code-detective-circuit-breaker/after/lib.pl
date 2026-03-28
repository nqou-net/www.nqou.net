use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Circuit Breaker パターン ===
# 失敗が閾値を超えたら回路を遮断し、外部サービス障害の連鎖崩壊を防ぐ。

# --- ExternalService（Before と同じ） ---
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

# --- CircuitBreaker（Circuit Breaker パターン） ---
package CircuitBreaker {
    use Moo;
    use Types::Standard qw(Int Num Str CodeRef);
    use Carp qw(croak);

    has failure_threshold  => (is => 'ro', isa => Int, default => 3);
    has recovery_timeout   => (is => 'ro', isa => Num, default => 30);
    has _state             => (is => 'rw', isa => Str, default => 'closed');
    has _failure_count     => (is => 'rw', isa => Int, default => 0);
    has _last_failure_time => (is => 'rw', isa => Num, default => 0);
    has _now_func          => (is => 'ro', isa => CodeRef,
                               default => sub { sub { time() } });

    sub call ($self, $action) {
        if ($self->_state eq 'open') {
            if ($self->_now_func->() - $self->_last_failure_time
                    >= $self->recovery_timeout) {
                $self->_state('half_open');
            }
            else {
                croak "Circuit is open: requests are blocked";
            }
        }

        my $result = eval { $action->() };
        if ($@) {
            $self->_on_failure;
            croak $@;
        }
        $self->_on_success;
        return $result;
    }

    sub _on_success ($self) {
        $self->_failure_count(0);
        $self->_state('closed');
    }

    sub _on_failure ($self) {
        $self->_failure_count($self->_failure_count + 1);
        $self->_last_failure_time($self->_now_func->());
        if ($self->_failure_count >= $self->failure_threshold) {
            $self->_state('open');
        }
    }

    sub state ($self) { $self->_state }
    sub failure_count ($self) { $self->_failure_count }
}

# --- ExternalApiClient（Circuit Breaker を使用） ---
package ExternalApiClient {
    use Moo;
    use Types::Standard qw(Object);

    has service => (is => 'ro', isa => Object, required => 1);
    has breaker => (is => 'ro', isa => Object, required => 1);

    sub call ($self, $params) {
        return $self->breaker->call(sub {
            $self->service->request($params);
        });
    }
}

1;
