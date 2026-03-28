use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Lazy Loading パターン ===
# 関連データは最初にアクセスされた時点で初めて読み込む。

# --- DataStore（Before と同じ） ---
package DataStore {
    use Moo;
    use Types::Standard qw(HashRef);

    has _data => (is => 'ro', isa => HashRef, default => sub { {} });

    our $TOTAL_QUERIES = 0;

    sub register ($self, $key, $value) {
        $self->_data->{$key} = $value;
    }

    sub query ($self, $key) {
        $TOTAL_QUERIES++;
        return $self->_data->{$key};
    }

    sub reset_counter { $TOTAL_QUERIES = 0 }
}

# --- Employee（Lazy Loading パターン） ---
package Employee {
    use Moo;
    use Types::Standard qw(Str Int ArrayRef HashRef Object);

    has id    => (is => 'ro', isa => Int, required => 1);
    has name  => (is => 'ro', isa => Str, required => 1);
    has store => (is => 'ro', isa => Object, required => 1);

    # Lazy: builder は最初のアクセス時まで実行されない
    has department  => (is => 'lazy', isa => HashRef);
    has attendance  => (is => 'lazy', isa => ArrayRef);
    has evaluations => (is => 'lazy', isa => ArrayRef);

    sub _build_department ($self) {
        return $self->store->query("dept:" . $self->id) // {};
    }

    sub _build_attendance ($self) {
        return $self->store->query("attendance:" . $self->id) // [];
    }

    sub _build_evaluations ($self) {
        return $self->store->query("evaluations:" . $self->id) // [];
    }
}

1;
