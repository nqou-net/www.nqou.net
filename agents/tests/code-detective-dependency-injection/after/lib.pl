use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Dependency Injection（コンストラクタ注入） ===
# 依存をコンストラクタの引数として明示的に受け取る。
# テスト時はモックを渡し、本番時は本物を渡す。

# --- InMemoryDB（テスト用のDB代替） ---
package InMemoryDB {
    use Moo;
    has records => (is => 'rw', default => sub { [] });

    sub insert ($self, $table, $record) {
        push @{ $self->records }, { table => $table, data => $record };
    }

    sub count ($self) { scalar @{ $self->records } }
}

# --- MockNotifier（テスト用の通知サービス代替） ---
package MockNotifier {
    use Moo;
    has sent => (is => 'rw', default => sub { [] });

    sub send ($self, %params) {
        push @{ $self->sent }, \%params;
    }

    sub sent_count ($self) { scalar @{ $self->sent } }
}

# --- AttendanceService（DI: 依存をコンストラクタで受け取る） ---
package AttendanceService {
    use Moo;

    has db       => (is => 'ro', required => 1);
    has notifier => (is => 'ro', required => 1);

    sub record_clock_in ($self, $employee_id) {
        my $now = time;
        $self->db->insert('clock_events', {
            employee_id => $employee_id,
            event_type  => 'clock_in',
            timestamp   => $now,
        });

        $self->notifier->send(
            to      => 'hr@company.internal',
            subject => "Clock-in: Employee $employee_id",
            body    => "Employee $employee_id clocked in at $now",
        );

        return { employee_id => $employee_id, timestamp => $now };
    }
}

1;
