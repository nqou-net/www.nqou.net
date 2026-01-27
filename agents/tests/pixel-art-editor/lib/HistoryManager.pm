# lib/HistoryManager.pm
package HistoryManager {
    use v5.36;
    use Moo;

    has undo_stack => (is => 'rw', default => sub { [] });
    has redo_stack => (is => 'rw', default => sub { [] });

    sub execute($self, $command) {
        $command->execute();
        push $self->undo_stack->@*, $command;
        # 新しい操作を実行したら、Redoスタックをクリア
        $self->redo_stack([]);
        say "[Execute] " . $command->description();
    }

    sub undo($self) {
        return unless $self->undo_stack->@*;
        my $command = pop $self->undo_stack->@*;
        $command->undo();
        push $self->redo_stack->@*, $command;
        say "[Undo] " . $command->description();
    }

    sub redo($self) {
        return unless $self->redo_stack->@*;
        my $command = pop $self->redo_stack->@*;
        $command->execute();
        push $self->undo_stack->@*, $command;
        say "[Redo] " . $command->description();
    }

    sub can_undo($self) {
        return scalar $self->undo_stack->@*;
    }

    sub can_redo($self) {
        return scalar $self->redo_stack->@*;
    }

    sub status($self) {
        return sprintf("Undo: %d / Redo: %d", 
            scalar($self->undo_stack->@*),
            scalar($self->redo_stack->@*)
        );
    }
}

1;
