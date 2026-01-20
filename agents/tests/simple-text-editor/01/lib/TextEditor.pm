use v5.36;

package Editor {
    use Moo;

    has text => (
        is      => 'rw',
        default => '',
    );

    sub insert ($self, $position, $string) {
        my $current  = $self->text;
        my $new_text = substr($current, 0, $position)
                     . $string
                     . substr($current, $position);
        $self->text($new_text);
    }

    sub delete ($self, $position, $length) {
        my $current  = $self->text;
        my $new_text = substr($current, 0, $position)
                     . substr($current, $position + $length);
        $self->text($new_text);
    }
}

1;
