package AlertHandler;
use v5.36;

sub new ($class, %args) {
    return bless {
        next_handler => undef,
        log          => $args{log} // [],
    }, $class;
}

sub set_next ($self, $handler) {
    $self->{next_handler} = $handler;
    $handler->{log}       = $self->{log};
    return $handler;
}

sub handle ($self, $alert) {
    if ($self->{next_handler}) {
        return $self->{next_handler}->handle($alert);
    }

    # チェーン終端: どのハンドラも処理しなかった
    $self->_log('UNKNOWN', 'log_only', $alert);
    return;
}

sub _notify_pagerduty ($self, $alert) {
    push $self->{log}->@*, "PAGERDUTY: [$alert->{type}] $alert->{message}";
}

sub _notify_slack ($self, $alert, $channel) {
    push $self->{log}->@*, "SLACK($channel): [$alert->{type}] $alert->{message}";
}

sub _log ($self, $level, $dest, $alert) {
    push $self->{log}->@*, "LOG[$level]($dest): [$alert->{type}] severity=$alert->{severity}";
}

sub get_log ($self) {
    return $self->{log}->@*;
}

1;
