package Command::StopService;
use v5.36;
use parent 'Command::Role';

sub execute ($self) {
    $self->{server}->log("Stopping service...");
    $self->{server}{state}{service} = 'stopped';
}

sub undo ($self) {
    $self->{server}->log("UNDO: Starting service...");
    $self->{server}{state}{service} = 'running';
}

1;
