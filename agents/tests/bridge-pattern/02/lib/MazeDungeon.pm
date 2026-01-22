# MazeDungeon.pm - 迷路型ダンジョン（完成版）
package MazeDungeon;
use v5.36;
use Moo;

# ダンジョンのサイズ（奇数にする必要あり）
has width  => ( is => 'ro', default => 41 );
has height => ( is => 'ro', default => 11 );

# マップデータ
has map => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_map',
);

# 訪問済みマス
has visited => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);

# 初期状態：すべて壁で埋める
sub _build_map ($self) {
    my @map;
    for my $y ( 0 .. $self->height - 1 ) {
        my @row;
        for my $x ( 0 .. $self->width - 1 ) {
            push @row, '#';
        }
        push @map, \@row;
    }
    return \@map;
}

# 迷路型アルゴリズム（再帰的バックトラック法）
sub generate ($self) {
    my $map = $self->map;

    # 開始地点（奇数座標）
    my $start_x = 1;
    my $start_y = 1;

    $self->_carve( $start_x, $start_y );
}

# 通路を掘る（再帰）
sub _carve ( $self, $x, $y ) {
    my $map     = $self->map;
    my $visited = $self->visited;

    # 現在地を床にして訪問済みにする
    $map->[$y][$x] = '.';
    $visited->{"$x,$y"} = 1;

    # 4方向をシャッフル
    my @directions = ( [ 0, -2 ], [ 0, 2 ], [ -2, 0 ], [ 2, 0 ] );
    @directions = sort { rand() <=> rand() } @directions;

    for my $dir (@directions) {
        my ( $dx, $dy ) = $dir->@*;
        my $nx = $x + $dx;
        my $ny = $y + $dy;

        # 範囲内かつ未訪問なら掘り進む
        if (   $nx > 0
            && $nx < $self->width - 1
            && $ny > 0
            && $ny < $self->height - 1
            && !$visited->{"$nx,$ny"} )
        {
            # 間の壁も掘る
            $map->[ $y + $dy / 2 ][ $x + $dx / 2 ] = '.';

            # 再帰
            $self->_carve( $nx, $ny );
        }
    }
}

# ASCII artで表示
sub render ($self) {
    my $map    = $self->map;
    my $output = '';

    for my $row ( $map->@* ) {
        $output .= join( '', $row->@* ) . "\n";
    }

    return $output;
}

1;
