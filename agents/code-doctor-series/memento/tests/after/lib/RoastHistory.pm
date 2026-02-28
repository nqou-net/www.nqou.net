package RoastHistory;
use v5.36;

sub new($class) {
    bless { stack => [] }, $class;
}

sub save($self, $memento) {
    push $self->{stack}->@*, $memento;
}

sub undo($self) {
    return undef unless $self->{stack}->@*;
    pop $self->{stack}->@*;
}

sub history($self) {
    return $self->{stack}->@*;
}

sub count($self) {
    scalar $self->{stack}->@*;
}

1;
