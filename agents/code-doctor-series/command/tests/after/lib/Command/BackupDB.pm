package Command::BackupDB;
use v5.36;
use parent 'Command::Role';

sub execute ($self) {
    $self->{server}->log("Backing up DB...");
    $self->{server}{state}{db} = 'backed_up';
}

sub undo ($self) {
    $self->{server}->log("UNDO: Restoring DB...");
    $self->{server}{state}{db} = 'normal';
}

1;
