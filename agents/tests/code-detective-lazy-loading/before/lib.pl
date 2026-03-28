use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: Eager Loading（過剰な事前読み込み） ===
# オブジェクト生成時に関連データをすべて即座に読み込む。

# --- DataStore（データ取得のシミュレーション） ---
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

# --- Employee（アンチパターン: Eager Loading） ---
package Employee {
    use Moo;
    use Types::Standard qw(Str Int ArrayRef HashRef Object);

    has id    => (is => 'ro', isa => Int, required => 1);
    has name  => (is => 'ro', isa => Str, required => 1);
    has store => (is => 'ro', isa => Object, required => 1);

    has department  => (is => 'lazy', isa => HashRef);
    has attendance  => (is => 'lazy', isa => ArrayRef);
    has evaluations => (is => 'lazy', isa => ArrayRef);

    # Eager: BUILD で生成時に全属性を強制ロード
    sub BUILD ($self, $args) {
        $self->department;
        $self->attendance;
        $self->evaluations;
    }

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
