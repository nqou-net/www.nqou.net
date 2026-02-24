package Kitchen;
use v5.36;
use Section;
use parent 'Section';

sub new($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{name} //= 'キッチン';
    return $self;
}

# 料理を準備する（他のセクションには一切触れない）
sub prepare($self, $order) {
    my $item = $order->{item} // '不明な料理';
    return "Kitchen: $item を調理中";
}

1;
