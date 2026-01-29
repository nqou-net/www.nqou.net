use v5.36;
use Test::More;

package Order {
    use Moo;
    
    # BAD: Mutable attributes
    has items => (is => 'rw', default => sub { [] });
    has total => (is => 'rw', default => 0);
    
    sub add_item ($self, $name, $price) {
        push $self->items->@*, { name => $name, price => $price };
        $self->total( $self->total + $price );
    }
    
    # BAD: Modifies internal state for calculation (Side Effect)
    sub apply_discount ($self, $rate) {
        $self->total( $self->total * (1 - $rate) );
    }
}

subtest 'The Mutable Trap' => sub {
    my $order = Order->new;
    $order->add_item('Widget A', 1000);
    $order->add_item('Widget B', 2000);
    
    is $order->total, 3000, 'Initial total is correct';
    
    # Scenario: We want to calculate a preview price specific to a user
    # But we modify the original order object!
    $order->apply_discount(0.1); # 10% off
    
    is $order->total, 2700, 'Discount applied';
    
    # Later in the code, we try to use the order simply for logging or another calculation
    # EXPECTED: 3000 (Original total)
    # ACTUAL: 2700 (State was mutated!)
    isnt $order->total, 3000, 'Original total is lost forever due to mutation';
};

done_testing;
