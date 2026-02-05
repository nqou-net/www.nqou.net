package Good::Notifier;
use v5.36;

# Abstraction
sub new {
    my ($class, %args) = @_;

    # Bridge: Implementationへの参照を保持
    die "Missing 'sender' argument" unless $args{sender};
    bless \%args, $class;
}

sub sender { shift->{sender} }

sub notify {
    my ($self, $message) = @_;

    # 委譲 (Delegation)
    $self->sender->send($self->format_message($message));
}

# 抽象メソッド的な位置づけ (RefinedAbstractionで実装)
sub format_message {
    my ($self, $message) = @_;
    return $message;
}

1;
