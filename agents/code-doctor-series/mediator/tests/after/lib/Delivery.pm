package Delivery;
use v5.36;
use Section;
use parent 'Section';

sub new($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{name} //= 'デリバリー';
    return $self;
}

# 配送を手配する（Mediator に登録するだけで追加完了！）
sub dispatch($self, $order) {
    my $item    = $order->{item}    // '不明';
    my $address = $order->{address} // '不明な住所';
    return "Delivery: $item を $address へ配送手配";
}

1;
