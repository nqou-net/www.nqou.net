package Bot::Observer::SlackNotifier;
use Moo;
with 'Bot::Observer::Role';

sub update {
    my ($self, $event) = @_;
    print "[Slack通知] " . ($event->{message} // '') . "\n";
}

1;
