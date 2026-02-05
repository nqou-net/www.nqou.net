package Good::Sender::Email;
use v5.36;
use Role::Tiny::With;
with 'Good::Sender::Role';

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub send {
    my ($self, $body) = @_;
    print "Sending Email: $body\n";
}

1;
