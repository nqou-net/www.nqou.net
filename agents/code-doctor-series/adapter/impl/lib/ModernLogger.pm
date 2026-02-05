package ModernLogger;
use v5.36;
use JSON::PP;

sub new($class) {
    return bless {json => JSON::PP->new->ascii}, $class;
}

# The interface is incompatible with LegacyLogger
sub log_json($self, %args) {

    # args: level, message, context
    my $level = $args{level} // 'info';
    my $msg   = $args{message};

    my $payload = {
        level     => $level,
        message   => $msg,
        timestamp => time(),
    };

    say $self->{json}->encode($payload);
}

1;
