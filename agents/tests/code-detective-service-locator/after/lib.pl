use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: DI（Dependency Injection） ===
# 依存をコンストラクタの引数として明示的に受け取る。
# テスト時はモックを渡し、本番時は本物を渡す。

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

# --- MockMailer（テスト用モック） ---
package MockMailer {
    use Moo;
    has sent => (is => 'rw', default => sub { [] });

    sub send ($self, %params) {
        push @{ $self->sent }, \%params;
    }

    sub sent_count ($self) { scalar @{ $self->sent } }
}

# --- OrderService（DI: 依存をコンストラクタで受け取る） ---
package OrderService {
    use Moo;

    has db     => (is => 'ro', required => 1);
    has mailer => (is => 'ro', required => 1);

    sub place_order ($self, $item_id, $quantity) {
        my $order = { id => 1001, item_id => $item_id, quantity => $quantity };
        $self->db->insert('orders', $order);
        $self->mailer->send(to => 'admin@example.com', subject => "New order: $item_id");

        return $order;
    }
}

1;
