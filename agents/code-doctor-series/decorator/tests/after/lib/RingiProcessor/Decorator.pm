package RingiProcessor::Decorator;
use v5.36;
use parent 'RingiProcessor';

# Decorator ベースクラス: 内部に $inner を持ち、process() を委譲する「包帯の型紙」

sub new ($class, %args) {
    my $inner = delete $args{inner} // die "Decorator requires 'inner' processor";
    my $self  = $class->SUPER::new(%args);
    $self->{inner} = $inner;
    return $self;
}

sub process ($self, $ringi) {
    return $self->{inner}->process($ringi);
}

1;
