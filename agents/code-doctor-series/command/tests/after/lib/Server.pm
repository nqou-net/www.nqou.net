package Server;
use v5.36;

sub new ($class) {
    bless {log => [], state => {app => 'old_version', service => 'running', db => 'normal'}}, $class;
}

sub log ($self, $msg) {
    push $self->{log}->@*, $msg;
}

1;
