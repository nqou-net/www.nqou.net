package AlertHandler::SslCertAlert;
use v5.36;
use parent -norequire, 'AlertHandler';

sub handle ($self, $alert) {
    return $self->SUPER::handle($alert) unless $alert->{type} eq 'ssl_cert';

    if ($alert->{severity} >= 80) {
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#security');
        $self->_log('CRITICAL', 'pagerduty+slack', $alert);
    }
    elsif ($alert->{severity} >= 50) {
        $self->_notify_slack($alert, '#security');
        $self->_log('WARNING', 'slack', $alert);
    }
    else {
        $self->_log('INFO', 'log_only', $alert);
    }
    return 1;
}

1;
