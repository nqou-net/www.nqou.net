package Bad::Notifier::Normal;
use v5.36;
use parent 'Bad::Notifier';

sub format_message {
    my ($self, $message) = @_;
    return "[Info] " . $message;
}

1;
