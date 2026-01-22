# DungeonTheme.pm - テーマの基底クラス
package DungeonTheme;
use v5.36;
use Moo;

# アルゴリズムを注入
has algorithm => (
    is       => 'ro',
    required => 1,
    does     => 'GenerationAlgorithm',
);

has width  => ( is => 'ro', default => 41 );
has height => ( is => 'ro', default => 11 );

has map => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_map',
);

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

# 生成をアルゴリズムに委譲
sub generate ($self) {
    $self->algorithm->generate( $self->map, $self->width, $self->height );
}

# 表示（テーマごとにオーバーライド）
sub render ($self) {
    my $map    = $self->map;
    my $output = '';

    for my $row ( $map->@* ) {
        for my $cell ( $row->@* ) {
            if ( $cell eq '#' ) {
                $output .= $self->wall_char;
            }
            else {
                $output .= $self->floor_char;
            }
        }
        $output .= "\n";
    }

    return $output;
}

# サブクラスでオーバーライド
sub wall_char ($self)  { '#' }
sub floor_char ($self) { '.' }

1;
