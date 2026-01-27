package Bot::Command::Die;
use Moo;
with 'Bot::Command::Role';

sub match {
    my ($self, $text) = @_;
    return {} if $text eq '/die';
    return undef;
}

sub execute {
    die "Intentional Check\n";
}

sub description { "/die" }

1;
