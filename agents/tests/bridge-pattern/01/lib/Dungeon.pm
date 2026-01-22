# Dungeon.pm - ダンジョンの基本構造（完成版）
package Dungeon;
use v5.36;
use Moo;

# ダンジョンのサイズ
has width  => ( is => 'ro', default => 40 );
has height => ( is => 'ro', default => 10 );

# マップデータ（二次元配列への参照）
has map => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_map',
);

# 初期状態：すべて壁で埋める
sub _build_map ($self) {
    my @map;
    for my $y ( 0 .. $self->height - 1 ) {
        my @row;
        for my $x ( 0 .. $self->width - 1 ) {
            push @row, '#';    # 壁
        }
        push @map, \@row;
    }
    return \@map;
}

# ランダムに床を配置
sub generate ($self) {
    my $map = $self->map;

    for my $y ( 1 .. $self->height - 2 ) {
        for my $x ( 1 .. $self->width - 2 ) {
            # 70%の確率で床にする
            if ( rand() < 0.7 ) {
                $map->[$y][$x] = '.';
            }
        }
    }
}

# ASCII artで表示
sub render ($self) {
    my $map = $self->map;
    my $output = '';

    for my $row ( $map->@* ) {
        $output .= join( '', $row->@* ) . "\n";
    }

    return $output;
}

1;
