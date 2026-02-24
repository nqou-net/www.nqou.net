package Waiter;
use v5.36;
use Section;
use parent 'Section';

sub new($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{name} //= 'ウェイター';
    return $self;
}

# 注文を受けて Mediator に通知するだけ
# （他のセクションを一切知らない！）
sub take_order($self, $order) {
    my $event = $order->{type} eq 'food'  ? 'food_order'
              : $order->{type} eq 'drink' ? 'drink_order'
              : $order->{type} eq 'both'  ? 'combo_order'
              :                             'food_order';

    return $self->mediator->notify($event, $order);
}

1;
