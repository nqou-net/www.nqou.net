package LoggerAdapter;
use v5.36;

# 1. Implement the Target interface (LegacyLogger)
# 2. delegate to Adaptee (ModernLogger)

sub new($class, $modern_logger) {
    return bless {adaptee => $modern_logger,}, $class;
}

# Match LegacyLogger's signature: log($self, $message)
sub log($self, $message) {

    # Delegate to ModernLogger with conversion
    $self->{adaptee}->log_json(
        level   => 'info',
        message => $message,
    );
}

1;
