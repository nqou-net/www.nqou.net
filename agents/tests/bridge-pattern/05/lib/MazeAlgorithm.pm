# MazeAlgorithm.pm - 迷路型アルゴリズム
package MazeAlgorithm;
use v5.36;
use Moo;

with 'GenerationAlgorithm';

has visited => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);

sub generate ( $self, $map, $width, $height ) {
    $self->visited( {} );    # リセット
    $self->_carve( $map, $width, $height, 1, 1 );
}

sub _carve ( $self, $map, $width, $height, $x, $y ) {
    my $visited = $self->visited;

    $map->[$y][$x] = '.';
    $visited->{"$x,$y"} = 1;

    my @directions = ( [ 0, -2 ], [ 0, 2 ], [ -2, 0 ], [ 2, 0 ] );
    @directions = sort { rand() <=> rand() } @directions;

    for my $dir (@directions) {
        my ( $dx, $dy ) = $dir->@*;
        my $nx = $x + $dx;
        my $ny = $y + $dy;

        if (   $nx > 0
            && $nx < $width - 1
            && $ny > 0
            && $ny < $height - 1
            && !$visited->{"$nx,$ny"} )
        {
            $map->[ $y + $dy / 2 ][ $x + $dx / 2 ] = '.';
            $self->_carve( $map, $width, $height, $nx, $ny );
        }
    }
}

1;
