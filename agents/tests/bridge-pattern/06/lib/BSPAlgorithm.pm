# BSPAlgorithm.pm - 部屋区分型アルゴリズム
package BSPAlgorithm;
use v5.36;
use Moo;

with 'GenerationAlgorithm';

# 最小領域サイズ
has min_size => ( is => 'ro', default => 6 );

# 領域リスト
has regions => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

# 部屋リスト
has rooms => (
    is      => 'rw',
    lazy    => 1,
    default => sub { [] },
);

sub generate ( $self, $map, $width, $height ) {
    # 初期化
    $self->regions( [] );
    $self->rooms( [] );

    # 領域を分割
    $self->_split_region( 1, 1, $width - 2, $height - 2 );

    # 各領域に部屋を配置
    for my $region ( $self->regions->@* ) {
        my ( $x, $y, $w, $h ) = $region->@*;
        my $room = $self->_create_room( $map, $x, $y, $w, $h );
        push $self->rooms->@*, $room if $room;
    }

    # 部屋を通路で接続
    $self->_connect_rooms($map);
}

# 領域を再帰的に分割
sub _split_region ( $self, $x, $y, $w, $h ) {
    my $min = $self->min_size;

    # 十分小さければ分割終了
    if ( $w < $min * 2 && $h < $min * 2 ) {
        push $self->regions->@*, [ $x, $y, $w, $h ];
        return;
    }

    # 縦分割か横分割かをランダムに決定
    my $split_horizontal = $h > $w ? 1 : ( $w > $h ? 0 : rand() > 0.5 );

    if ($split_horizontal) {
        # 横分割
        if ( $h >= $min * 2 ) {
            my $split_y = $y + $min + int( rand( $h - $min * 2 + 1 ) );
            $self->_split_region( $x, $y, $w, $split_y - $y );
            $self->_split_region( $x, $split_y, $w, $y + $h - $split_y );
        }
        else {
            push $self->regions->@*, [ $x, $y, $w, $h ];
        }
    }
    else {
        # 縦分割
        if ( $w >= $min * 2 ) {
            my $split_x = $x + $min + int( rand( $w - $min * 2 + 1 ) );
            $self->_split_region( $x, $y, $split_x - $x, $h );
            $self->_split_region( $split_x, $y, $x + $w - $split_x, $h );
        }
        else {
            push $self->regions->@*, [ $x, $y, $w, $h ];
        }
    }
}

# 領域内に部屋を作成
sub _create_room ( $self, $map, $x, $y, $w, $h ) {
    # 領域より少し小さい部屋を作成
    my $room_w = int( $w * 0.6 ) + int( rand( $w * 0.3 ) );
    my $room_h = int( $h * 0.6 ) + int( rand( $h * 0.3 ) );
    my $room_x = $x + int( rand( $w - $room_w ) );
    my $room_y = $y + int( rand( $h - $room_h ) );

    # 部屋を床で埋める
    for my $ry ( $room_y .. $room_y + $room_h - 1 ) {
        for my $rx ( $room_x .. $room_x + $room_w - 1 ) {
            $map->[$ry][$rx] = '.';
        }
    }

    return [ $room_x, $room_y, $room_w, $room_h ];
}

# 部屋同士を通路で接続
sub _connect_rooms ( $self, $map ) {
    my @rooms = $self->rooms->@*;

    for my $i ( 1 .. $#rooms ) {
        my ( $x1, $y1, $w1, $h1 ) = $rooms[ $i - 1 ]->@*;
        my ( $x2, $y2, $w2, $h2 ) = $rooms[$i]->@*;

        # 部屋の中心
        my $cx1 = $x1 + int( $w1 / 2 );
        my $cy1 = $y1 + int( $h1 / 2 );
        my $cx2 = $x2 + int( $w2 / 2 );
        my $cy2 = $y2 + int( $h2 / 2 );

        # L字型の通路を掘る
        if ( rand() > 0.5 ) {
            $self->_carve_h_corridor( $map, $cx1, $cx2, $cy1 );
            $self->_carve_v_corridor( $map, $cy1, $cy2, $cx2 );
        }
        else {
            $self->_carve_v_corridor( $map, $cy1, $cy2, $cx1 );
            $self->_carve_h_corridor( $map, $cx1, $cx2, $cy2 );
        }
    }
}

# 水平通路を掘る
sub _carve_h_corridor ( $self, $map, $x1, $x2, $y ) {
    my ( $min, $max ) = $x1 < $x2 ? ( $x1, $x2 ) : ( $x2, $x1 );
    for my $x ( $min .. $max ) {
        $map->[$y][$x] = '.';
    }
}

# 垂直通路を掘る
sub _carve_v_corridor ( $self, $map, $y1, $y2, $x ) {
    my ( $min, $max ) = $y1 < $y2 ? ( $y1, $y2 ) : ( $y2, $y1 );
    for my $y ( $min .. $max ) {
        $map->[$y][$x] = '.';
    }
}

1;
