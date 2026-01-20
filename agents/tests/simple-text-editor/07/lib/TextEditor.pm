use v5.36;

package Editor {
    use Moo;

    has text => (
        is      => 'rw',
        default => '',
    );
}

package Command::Role {
    use Moo::Role;

    requires 'execute';
    requires 'undo';
}

package InsertCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has string => (
        is       => 'ro',
        required => 1,
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $string   = $self->string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . $string
                     . substr($current, $position);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = length($self->string);

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }
}

package DeleteCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has length => (
        is       => 'ro',
        required => 1,
    );

    has _deleted_string => (
        is      => 'rw',
        default => '',
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = $self->length;

        my $current = $editor->text;
        my $deleted = substr($current, $position, $length);
        $self->_deleted_string($deleted);

        my $new_text = substr($current, 0, $position)
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $deleted  = $self->_deleted_string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . $deleted
                     . substr($current, $position);
        $editor->text($new_text);
    }
}

package History {
    use Moo;

    has undo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    has redo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    sub execute_command ($self, $command) {
        $command->execute;
        push $self->undo_stack->@*, $command;
        $self->redo_stack->@* = ();
    }

    sub undo ($self) {
        return unless $self->undo_stack->@*;

        my $command = pop $self->undo_stack->@*;
        $command->undo;
        push $self->redo_stack->@*, $command;
    }

    sub redo ($self) {
        return unless $self->redo_stack->@*;

        my $command = pop $self->redo_stack->@*;
        $command->execute;
        push $self->undo_stack->@*, $command;
    }
}

1;
