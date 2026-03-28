use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Service Locator による暗黙の依存 ===
# グローバルなレジストリから依存オブジェクトを取得するため、
# テスト時にモック差し替えが困難で、本番データを壊すリスクがある。

# --- InMemoryDB（DB のスタブ） ---
package InMemoryDB {
    use Moo;
    has records => (is => 'rw', default => sub { [] });

    sub insert ($self, $table, $record) {
        push @{ $self->records }, { table => $table, data => $record };
    }

    sub count ($self) { scalar @{ $self->records } }
}

# --- Mailer（メール送信のスタブ） ---
package Mailer {
    use Moo;
    has sent => (is => 'rw', default => sub { [] });

    sub send ($self, %params) {
        push @{ $self->sent }, \%params;
    }

    sub sent_count ($self) { scalar @{ $self->sent } }
}

# --- ServiceLocator（グローバルレジストリ） ---
package ServiceLocator {
    use Moo;

    my %registry;

    sub register ($class, $name, $instance) {
        $registry{$name} = $instance;
    }

    sub get ($class, $name) {
        die "Service not found: $name\n" unless exists $registry{$name};
        return $registry{$name};
    }

    sub clear ($class) {
        %registry = ();
    }
}

# --- OrderService（アンチパターン: ServiceLocatorから依存を取得） ---
package OrderService {
    use Moo;

    sub place_order ($self, $item_id, $quantity) {
        my $db     = ServiceLocator->get('db');
        my $mailer = ServiceLocator->get('mailer');

        my $order = { id => 1001, item_id => $item_id, quantity => $quantity };
        $db->insert('orders', $order);
        $mailer->send(to => 'admin@example.com', subject => "New order: $item_id");

        return $order;
    }
}

1;
