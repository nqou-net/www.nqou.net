package AlertHandler::ProcessAlert;
use v5.36;
use parent -norequire, 'AlertHandler';

sub handle ($self, $alert) {
    return $self->SUPER::handle($alert) unless $alert->{type} eq 'process';

    if ($alert->{message} =~ /OOM/) {
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#alerts');
        $self->_notify_slack($alert, '#infra');
        $self->_log('CRITICAL', 'pagerduty+slack_multi', $alert);
    }
    elsif ($alert->{severity} >= 70) {
        $self->_notify_slack($alert, '#alerts');
        $self->_log('WARNING', 'slack', $alert);
    }
    else {
        $self->_log('INFO', 'log_only', $alert);
    }
    return 1;
}

1;
