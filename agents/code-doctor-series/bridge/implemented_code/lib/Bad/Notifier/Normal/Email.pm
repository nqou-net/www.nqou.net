package Bad::Notifier::Normal::Email;
use v5.36;
use parent 'Bad::Notifier::Normal';

sub send {
    my ($self, $message) = @_;
    my $formatted = $self->format_message($message);
    print "Sending Email: $formatted\n";
}

1;
