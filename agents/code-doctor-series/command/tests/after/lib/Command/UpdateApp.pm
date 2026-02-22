package Command::UpdateApp;
use v5.36;
use parent 'Command::Role';

sub new ($class, $server, $should_fail = 0) {
    my $self = $class->SUPER::new($server);
    $self->{should_fail} = $should_fail;
    return $self;
}

sub execute ($self) {
    $self->{server}->log("Updating application...");
    die "Network error during update" if $self->{should_fail};
    $self->{server}{state}{app} = 'new_version';
}

sub undo ($self) {
    $self->{server}->log("UNDO: Reverting application...");
    $self->{server}{state}{app} = 'old_version';
}

1;
