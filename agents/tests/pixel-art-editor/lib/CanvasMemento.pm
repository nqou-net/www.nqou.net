# lib/CanvasMemento.pm
package CanvasMemento {
    use v5.36;
    use Moo;

    has state => (is => 'ro', required => 1);

    sub get_state($self) {
        return $self->state;
    }
}

1;
