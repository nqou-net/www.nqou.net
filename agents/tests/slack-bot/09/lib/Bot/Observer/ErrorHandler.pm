package Bot::Observer::ErrorHandler;
use Moo;
with 'Bot::Observer::Role';

sub update {
    my ($self, $event) = @_;
    return unless $event->{type} eq 'error';
    print "[DEV RECOVERY] Error caught: " . $event->{error} . "\n";
}

1;
