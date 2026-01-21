#!/usr/bin/env perl
use v5.36;
use Devel::Size qw(total_size);

package BulletType {
    use Moo;

    # 内部状態（共有可能）
    has shape => (is => 'ro', required => 1);
    has color => (is => 'ro', required => 1);
    has size  => (is => 'ro', required => 1);
    has char  => (is => 'ro', required => 1);

    sub render($self, $x, $y) {
        my $char = $self->char;
        say "$char at ($x, $y)";
    }

    sub describe($self) {
        my $shape = $self->shape;
        my $color = $self->color;
        my $size  = $self->size;
        return "[$color $shape, size=$size]";
    }
}

# 弾の種類を定義（3種類だけ）
my $red_circle = BulletType->new(
    shape => 'circle', color => 'red', size => 8, char => '●',
);
my $blue_star = BulletType->new(
    shape => 'star', color => 'blue', size => 12, char => '★',
);
my $green_laser = BulletType->new(
    shape => 'laser', color => 'green', size => 4, char => '|',
);

say "弾の種類:";
say "  " . $red_circle->describe;
say "  " . $blue_star->describe;
say "  " . $green_laser->describe;
say "";

# 弾の位置情報（外部状態）を配列で管理
my @bullets;
for my $i (0 .. 99) {
    push @bullets, {
        type => $red_circle,  # 内部状態への参照（共有）
        x    => 100 + $i,     # 外部状態
        y    => 200,
        vx   => 0,
        vy   => 5,
    };
}

say "弾の数: " . scalar(@bullets);
say "";

# 描画（外部状態を渡す）
say "最初の3発を描画:";
for my $bullet (@bullets[0..2]) {
    my $type = $bullet->{type};
    $type->render($bullet->{x}, $bullet->{y});
}

# メモリ使用量を確認
my $bullets_size = total_size(\@bullets);
say "";
say "弾100発のメモリ: " . sprintf("%.1f", $bullets_size / 1024) . "KB";
