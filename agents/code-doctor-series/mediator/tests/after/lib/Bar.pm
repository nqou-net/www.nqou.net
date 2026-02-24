package Bar;
use v5.36;
use Section;
use parent 'Section';

sub new($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{name} //= 'バー';
    return $self;
}

# ドリンクを準備する（他のセクションには一切触れない）
sub prepare($self, $order) {
    my $item = $order->{item} // '不明なドリンク';
    return "Bar: $item を準備中";
}

1;
