use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Hard-coded Dependencies（メソッド内で直接 new する密結合） ===
# クラス内部で依存先を直接インスタンス化しているため、
# テスト時にモックへ差し替える手段がなく、テスト不能になる。

# --- Database（本番DB接続のスタブ） ---
package Database {
    use Moo;
    has dsn     => (is => 'ro', required => 1);
    has records => (is => 'rw', default => sub { [] });

    sub insert ($self, $table, $record) {
        push @{ $self->records }, { table => $table, data => $record };
    }

    sub count ($self) { scalar @{ $self->records } }
}

# --- NotificationService（メール送信のスタブ） ---
package NotificationService {
    use Moo;
    has smtp_host => (is => 'ro', required => 1);
    has sent      => (is => 'rw', default => sub { [] });

    sub send ($self, %params) {
        push @{ $self->sent }, \%params;
    }

    sub sent_count ($self) { scalar @{ $self->sent } }
}

# --- AttendanceService（アンチパターン: メソッド内で直接 new） ---
package AttendanceService {
    use Moo;

    sub record_clock_in ($self, $employee_id) {
        my $db = Database->new(dsn => 'dbi:Pg:dbname=attendance_prod');
        my $now = time;
        $db->insert('clock_events', {
            employee_id => $employee_id,
            event_type  => 'clock_in',
            timestamp   => $now,
        });

        my $notifier = NotificationService->new(
            smtp_host => 'smtp.company.internal',
        );
        $notifier->send(
            to      => 'hr@company.internal',
            subject => "Clock-in: Employee $employee_id",
            body    => "Employee $employee_id clocked in at $now",
        );

        return { employee_id => $employee_id, timestamp => $now };
    }
}

1;
