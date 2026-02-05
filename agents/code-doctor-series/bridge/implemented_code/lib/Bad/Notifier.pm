package Bad::Notifier;
use v5.36;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub send {
    my ($self, $message) = @_;
    die "Abstract method 'send' called";
}

1;
