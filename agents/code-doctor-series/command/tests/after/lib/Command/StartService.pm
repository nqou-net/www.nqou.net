package Command::StartService;
use v5.36;
use parent 'Command::Role';

sub execute ($self) {
    $self->{server}->log("Starting service...");
    $self->{server}{state}{service} = 'running';
}

sub undo ($self) {
    $self->{server}->log("UNDO: Stopping service...");
    $self->{server}{state}{service} = 'stopped';
}

1;
