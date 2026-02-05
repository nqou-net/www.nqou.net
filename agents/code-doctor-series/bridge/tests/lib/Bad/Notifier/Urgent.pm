package Bad::Notifier::Urgent;
use v5.36;
use parent 'Bad::Notifier';

sub format_message {
    my ($self, $message) = @_;
    return "[URGENT] " . uc($message) . " !!!";
}

1;
