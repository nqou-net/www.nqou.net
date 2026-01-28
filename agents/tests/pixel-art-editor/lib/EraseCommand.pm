# lib/EraseCommand.pm
package EraseCommand {
    use v5.36;
    use Moo;

    has canvas  => (is => 'ro', required => 1);
    has x       => (is => 'ro', required => 1);
    has y       => (is => 'ro', required => 1);
    has memento => (is => 'rw');

    sub execute($self) {
        $self->memento($self->canvas->create_memento());
        $self->canvas->set_pixel($self->x, $self->y, ' ');
    }

    sub undo($self) {
        if ($self->memento) {
            $self->canvas->restore_memento($self->memento);
        }
    }

    sub description($self) {
        return sprintf("Erase at (%d, %d)", $self->x, $self->y);
    }
}

1;
