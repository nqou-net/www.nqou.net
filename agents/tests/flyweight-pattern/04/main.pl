#!/usr/bin/env perl
use v5.36;
# NOTE: Time::HiRes sleep calls are removed for non-interactive testing

package BulletType {
    use Moo;

    has char  => (is => 'ro', required => 1);
    has color => (is => 'ro', default => 'white');

    # 外部状態（位置）を受け取って描画
    sub render($self, $x, $y, $screen) {
        my $ix = int($x);
        my $iy = int($y);

        # 画面外チェック
        return if $iy < 0 || $iy >= @$screen;
        return if $ix < 0 || $ix >= length($screen->[$iy]);

        # 画面バッファに描画
        substr($screen->[$iy], $ix, 1) = $self->char;
    }
}

package BulletFactory {
    use Moo;

    has _cache => (is => 'ro', default => sub { {} });

    has _definitions => (
        is => 'ro',
        default => sub {
            {
                circle => { char => '●', color => 'red' },
                star   => { char => '★', color => 'blue' },
                dot    => { char => '・', color => 'green' },
                arrow  => { char => '→', color => 'yellow' },
            }
        },
    );

    sub get($self, $key) {
        my $cache = $self->_cache;
        my $defs  = $self->_definitions;

        $cache->{$key} //= do {
            my $def = $defs->{$key} or die "Unknown: $key";
            BulletType->new(%$def);
        };
    }

    sub count($self) { scalar keys %{$self->_cache} }
}

# メイン処理
my $WIDTH  = 50;
my $HEIGHT = 20;
my $factory = BulletFactory->new;

# 弾を生成
my @bullets;
my $cx = $WIDTH / 2;
my $cy = $HEIGHT / 2;

for my $wave (0 .. 2) {
    for my $i (0 .. 11) {
        my $angle = ($i * 30 + $wave * 10) * 3.14159 / 180;
        my $type = qw(circle star dot)[$wave];
        push @bullets, {
            type => $factory->get($type),
            x    => $cx,
            y    => $cy,
            vx   => cos($angle) * (1.5 - $wave * 0.2),
            vy   => sin($angle) * 0.7,
            born => $wave * 2,
        };
    }
}

say "弾の総数: " . scalar(@bullets);
say "BulletTypeオブジェクト数: " . $factory->count;
say "";

# 1フレームだけ描画テスト
my $frame = 5;
my @screen = map { " " x $WIDTH } (1 .. $HEIGHT);

for my $b (@bullets) {
    next if $frame < $b->{born};
    $b->{x} += $b->{vx} * 5;  # 5フレーム分移動
    $b->{y} += $b->{vy} * 5;
    $b->{type}->render($b->{x}, $b->{y}, \@screen);
}

say "=== 描画結果（1フレーム）===";
say $_ for @screen;
say "";
say "完了！";
