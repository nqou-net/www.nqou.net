package LegacyLogger;
use v5.36;

sub new($class) {
    return bless {}, $class;
}

sub log($self, $message) {

    # Simple text output
    say "[LOG] $message";
}

1;
