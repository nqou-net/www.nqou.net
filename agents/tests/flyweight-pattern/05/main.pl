#!/usr/bin/env perl
use v5.36;
# NOTE: Time::HiRes sleep calls removed for non-interactive testing
# NOTE: ANSI escape sequences removed for cleaner output

# ============================================================
# BulletType: 弾の種類（内部状態）
# ============================================================
package BulletType {
    use Moo;

    has name  => (is => 'ro', required => 1);
    has char  => (is => 'ro', required => 1);
    has color => (is => 'ro', default => 'white');

    sub render($self, $x, $y, $screen) {
        my $ix = int($x);
        my $iy = int($y);
        return if $iy < 0 || $iy >= @$screen;
        return if $ix < 0 || $ix >= length($screen->[$iy]);
        substr($screen->[$iy], $ix, 1) = $self->char;
    }
}

# ============================================================
# BulletFactory: 弾の種類を管理（オブジェクトプール）
# ============================================================
package BulletFactory {
    use Moo;

    has _cache => (is => 'ro', default => sub { {} });

    has _definitions => (
        is => 'ro',
        default => sub {
            {
                circle => { name => 'circle', char => '●' },
                star   => { name => 'star',   char => '★' },
                dot    => { name => 'dot',    char => '・' },
                arrow  => { name => 'arrow',  char => '→' },
                wave   => { name => 'wave',   char => '〜' },
            }
        },
    );

    sub get($self, $key) {
        my $cache = $self->_cache;
        my $defs  = $self->_definitions;
        $cache->{$key} //= BulletType->new(%{$defs->{$key}});
    }

    sub count($self) {
        scalar keys %{$self->_cache};
    }

    sub types($self) {
        sort keys %{$self->_cache};
    }
}

# ============================================================
# BattleField: 戦場を管理（弾の生成・移動・描画）
# ============================================================
package BattleField {
    use Moo;

    has width   => (is => 'ro', required => 1);
    has height  => (is => 'ro', required => 1);
    has factory => (is => 'ro', required => 1);
    has bullets => (is => 'ro', default => sub { [] });

    # 弾を生成
    sub spawn($self, $type_key, $x, $y, $vx, $vy) {
        push @{$self->bullets}, {
            type => $self->factory->get($type_key),
            x    => $x,
            y    => $y,
            vx   => $vx,
            vy   => $vy,
        };
    }

    # 弾幕パターン: 放射状
    sub spawn_radial($self, $type_key, $cx, $cy, $count, $speed) {
        for my $i (0 .. $count - 1) {
            my $angle = $i * (360 / $count) * 3.14159 / 180;
            $self->spawn(
                $type_key,
                $cx, $cy,
                cos($angle) * $speed,
                sin($angle) * $speed * 0.5,
            );
        }
    }

    # 弾幕パターン: 螺旋
    sub spawn_spiral($self, $type_key, $cx, $cy, $waves, $per_wave, $speed) {
        for my $wave (0 .. $waves - 1) {
            for my $i (0 .. $per_wave - 1) {
                my $angle = ($i * (360 / $per_wave) + $wave * 15) * 3.14159 / 180;
                push @{$self->bullets}, {
                    type => $self->factory->get($type_key),
                    x    => $cx,
                    y    => $cy,
                    vx   => cos($angle) * $speed,
                    vy   => sin($angle) * $speed * 0.5,
                    born => $wave * 2,  # 遅延生成
                };
            }
        }
    }

    # 弾を移動
    sub update($self, $frame) {
        my @alive;
        for my $b (@{$self->bullets}) {
            # 遅延生成チェック
            next if defined $b->{born} && $frame < $b->{born};

            # 移動
            $b->{x} += $b->{vx};
            $b->{y} += $b->{vy};

            # 画面内なら生存
            if ($b->{x} >= -5 && $b->{x} < $self->width + 5 &&
                $b->{y} >= -5 && $b->{y} < $self->height + 5) {
                push @alive, $b;
            }
        }
        @{$self->bullets} = @alive;
    }

    # 描画
    sub render($self, $frame) {
        my @screen = map { " " x $self->width } (1 .. $self->height);

        for my $b (@{$self->bullets}) {
            next if defined $b->{born} && $frame < $b->{born};
            $b->{type}->render($b->{x}, $b->{y}, \@screen);
        }

        return \@screen;
    }

    # 統計を表示
    sub stats($self) {
        my $bullet_count = scalar @{$self->bullets};
        my $type_count = $self->factory->count;
        return "弾: $bullet_count 発 / BulletType: $type_count 種類";
    }
}

# ============================================================
# メイン処理
# ============================================================
my $WIDTH  = 60;
my $HEIGHT = 25;
my $FRAMES = 5;  # テスト用に短縮

my $factory = BulletFactory->new;
my $field = BattleField->new(
    width   => $WIDTH,
    height  => $HEIGHT,
    factory => $factory,
);

# 弾幕を生成
my $cx = $WIDTH / 2;
my $cy = $HEIGHT / 2;

# 3種類の弾幕パターンを重ねる
$field->spawn_spiral('circle', $cx, $cy, 3, 12, 1.5);
$field->spawn_spiral('star',   $cx, $cy, 2, 8,  1.2);
$field->spawn_radial('dot',    $cx, $cy, 16, 2.0);

# 初期統計
say "=== 弾幕シューティングエンジン ===";
say $field->stats;
say "";
say "使用中のBulletType: " . join(", ", $factory->types);
say "";

# テスト用ループ（非対話的）
for my $frame (0 .. $FRAMES) {
    my $screen = $field->render($frame);
    $field->update($frame);
}

# 最終統計
say "=== 完成！ ===";
say "弾幕シューティングエンジンが動作しました。";
say "";
say "ポイント:";
say "  ✓ 大量の弾を少数のBulletTypeオブジェクトで管理";
say "  ✓ BulletFactoryでオブジェクトプールを実現";
say "  ✓ BattleFieldで弾の生成・移動・描画を一元管理";
