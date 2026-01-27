# lib/Canvas.pm
package Canvas {
    use v5.36;
    use Moo;
    use Term::ANSIColor qw(colored);
    use Storable qw(dclone);

    has width  => (is => 'ro', required => 1);
    has height => (is => 'ro', required => 1);
    has pixels => (is => 'rw', lazy => 1, builder => '_build_pixels');

    sub _build_pixels($self) {
        my @pixels;
        for my $y (0 .. $self->height - 1) {
            for my $x (0 .. $self->width - 1) {
                $pixels[$y][$x] = ' ';  # 空白で初期化
            }
        }
        return \@pixels;
    }

    sub set_pixel($self, $x, $y, $color) {
        return if $x < 0 || $x >= $self->width;
        return if $y < 0 || $y >= $self->height;
        $self->pixels->[$y][$x] = $color;
    }

    sub get_pixel($self, $x, $y) {
        return ' ' if $x < 0 || $x >= $self->width;
        return ' ' if $y < 0 || $y >= $self->height;
        return $self->pixels->[$y][$x];
    }

    sub erase_pixel($self, $x, $y) {
        $self->set_pixel($x, $y, ' ');
    }

    sub display($self) {
        say "+" . ("-" x ($self->width * 2)) . "+";
        for my $y (0 .. $self->height - 1) {
            print "|";
            for my $x (0 .. $self->width - 1) {
                my $pixel = $self->pixels->[$y][$x];
                if ($pixel eq ' ') {
                    print "  ";
                } else {
                    print colored("██", $pixel);
                }
            }
            say "|";
        }
        say "+" . ("-" x ($self->width * 2)) . "+";
    }

    sub create_memento($self) {
        return CanvasMemento->new(state => dclone($self->pixels));
    }

    sub restore_memento($self, $memento) {
        $self->pixels(dclone($memento->get_state()));
    }
}

1;
