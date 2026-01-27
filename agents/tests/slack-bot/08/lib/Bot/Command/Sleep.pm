package Bot::Command::Sleep;
use Moo;
with 'Bot::Command::Role';

sub match {
    my ($self, $text) = @_;
    return {} if $text eq '/sleep';
    return undef;
}

sub execute {
    my ($self, $args) = @_;
    sleep 5; # Longer than timeout
    return "おはよう";
}

sub description { "/sleep" }

1;
