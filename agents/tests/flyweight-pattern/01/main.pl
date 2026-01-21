#!/usr/bin/env perl
use v5.36;
use Devel::Size qw(total_size);

package Bullet {
    use Moo;

    # 弾の見た目（共有可能…のはず）
    has shape => (is => 'ro', required => 1);
    has color => (is => 'ro', required => 1);
    has size  => (is => 'ro', required => 1);

    # 弾の位置と速度（弾ごとに異なる）
    has x  => (is => 'rw', required => 1);
    has y  => (is => 'rw', required => 1);
    has vx => (is => 'ro', required => 1);
    has vy => (is => 'ro', required => 1);

    sub move($self) {
        $self->x($self->x + $self->vx);
        $self->y($self->y + $self->vy);
    }

    sub render($self) {
        my $shape = $self->shape;
        my $color = $self->color;
        my $x = $self->x;
        my $y = $self->y;
        say "[$color $shape] at ($x, $y)";
    }
}

# メモリ使用量を計測
my @bullets;
for my $i (0 .. 99) {
    push @bullets, Bullet->new(
        shape => 'circle',
        color => 'red',
        size  => 8,
        x     => 100 + $i,
        y     => 200,
        vx    => 0,
        vy    => 5,
    );
}

say "弾の数: " . scalar(@bullets);

my $size = total_size(\@bullets);
my $size_kb = sprintf("%.1f", $size / 1024);
say "メモリ使用量: ${size_kb}KB";

# 弾を動かして表示
for my $bullet (@bullets[0..2]) {
    $bullet->render;
    $bullet->move;
    $bullet->render;
    say "---";
}
