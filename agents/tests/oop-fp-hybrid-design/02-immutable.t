use v5.36;
use Test::More;

package ImmutableOrder {
    use Moo;

    # GOOD: Read-only attributes
    has items => (is => 'ro', default => sub { [] });
    has total => (is => 'ro', default => 0);

    sub add_item ($self, $name, $price) {

        # Returns a NEW object
        return $self->new(
            items => [$self->items->@*, {name => $name, price => $price}],
            total => $self->total + $price,
        );
    }

    sub with_discount ($self, $rate) {

        # Returns a NEW object with modified total
        return $self->new(
            items => $self->items,                # Share reference (safe if items content is deeper immutable, or if we assume array ref itself is not mutated)
            total => $self->total * (1 - $rate),
        );
    }
}

subtest 'The Immutable Solution' => sub {
    my $order = ImmutableOrder->new;

    # Functional update style
    $order = $order->add_item('Widget A', 1000);
    $order = $order->add_item('Widget B', 2000);

    is $order->total, 3000, 'Initial total is correct';

    # Scenario: Calculate preview price
    my $preview_order = $order->with_discount(0.1);

    is $preview_order->total, 2700, 'Preview order has discounted total';

    # Original order remains untouched!
    is $order->total, 3000, 'Original total is preserved safely';
};

done_testing;
