# RandomAlgorithm.pm - ランダム配置アルゴリズム
package RandomAlgorithm;
use v5.36;
use Moo;

with 'GenerationAlgorithm';

sub generate ( $self, $map, $width, $height ) {
    for my $y ( 1 .. $height - 2 ) {
        for my $x ( 1 .. $width - 2 ) {
            if ( rand() < 0.7 ) {
                $map->[$y][$x] = '.';
            }
        }
    }
}

1;
