#!/usr/bin/env perl
use v5.36;

# ============================================================
# Flyweight: 共有されるオブジェクト
# 内部状態（Intrinsic State）を保持
# ============================================================
package BulletType {
    use Moo;

    # 内部状態: 形状、色、表示文字（共有可能）
    has name  => (is => 'ro', required => 1);
    has char  => (is => 'ro', required => 1);
    has color => (is => 'ro', default => 'white');

    # 外部状態（位置）を受け取って描画
    sub render($self, $x, $y) {
        my $char = $self->char;
        say "$char at ($x, $y)";
    }

    sub describe($self) {
        my $name  = $self->name;
        my $color = $self->color;
        return "[$color $name]";
    }
}

# ============================================================
# FlyweightFactory: Flyweightオブジェクトを管理・提供
# オブジェクトプールによるキャッシュ
# ============================================================
package BulletFactory {
    use Moo;

    # キャッシュ（オブジェクトプール）
    has _cache => (is => 'ro', default => sub { {} });

    # 弾種の定義
    has _definitions => (
        is => 'ro',
        default => sub {
            {
                circle => { name => 'circle', char => '●', color => 'red' },
                star   => { name => 'star',   char => '★', color => 'blue' },
                dot    => { name => 'dot',    char => '・', color => 'green' },
            }
        },
    );

    # Flyweightを取得（キャッシュになければ作成）
    sub get($self, $key) {
        my $cache = $self->_cache;
        my $defs  = $self->_definitions;

        # //= でキャッシュ機構を実現
        $cache->{$key} //= do {
            my $def = $defs->{$key}
                or die "Unknown bullet type: $key";
            BulletType->new(%$def);
        };
    }

    sub count($self) {
        scalar keys %{$self->_cache};
    }
}

# ============================================================
# Client: Flyweightを使用するクラス
# 外部状態（Extrinsic State）を管理
# ============================================================
package BattleField {
    use Moo;

    has factory => (is => 'ro', required => 1);
    has bullets => (is => 'ro', default => sub { [] });

    # 弾を生成（外部状態を保持）
    sub spawn($self, $type_key, $x, $y, $vx, $vy) {
        push @{$self->bullets}, {
            type => $self->factory->get($type_key),  # Flyweightへの参照
            x    => $x,   # 外部状態
            y    => $y,
            vx   => $vx,
            vy   => $vy,
        };
    }

    # 描画（外部状態を渡す）
    sub render_all($self) {
        for my $bullet (@{$self->bullets}) {
            my $type = $bullet->{type};
            $type->render($bullet->{x}, $bullet->{y});
        }
    }

    sub stats($self) {
        my $bullet_count = scalar @{$self->bullets};
        my $type_count = $self->factory->count;
        return "弾: $bullet_count 発 / BulletType: $type_count 種類";
    }
}

# ============================================================
# デモ: Flyweightパターンの効果を確認
# ============================================================
my $factory = BulletFactory->new;
my $field = BattleField->new(factory => $factory);

# 100発の弾を生成（内部状態は3種類だけ）
for my $i (0 .. 99) {
    my @types = qw(circle star dot);
    my $type_key = $types[$i % 3];
    $field->spawn($type_key, $i * 5, $i * 2, 0, 1);
}

say "=== Flyweightパターン デモ ===";
say "";
say $field->stats;
say "";
say "ポイント:";
say "  ✓ 100発の弾に対して、BulletTypeは3つだけ";
say "  ✓ 内部状態（形状・色）は共有される";
say "  ✓ 外部状態（位置・速度）は弾ごとに異なる";
say "";
say "先頭5発を表示:";
for my $bullet (@{$field->bullets}[0..4]) {
    my $type = $bullet->{type};
    my $desc = $type->describe;
    say "  $desc at ($bullet->{x}, $bullet->{y})";
}
