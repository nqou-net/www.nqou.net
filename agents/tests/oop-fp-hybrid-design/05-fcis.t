use v5.36;
use Test::More;

# --- Functional Core ---
package OrderCore {
    use Moo;
    use List::Util qw(sum0);

    # Immutable DTO
    has items => (is => 'ro');

    sub total ($self) {
        return sum0 map { $_->{price} } $self->items->@*;
    }

    sub with_item ($self, $item) {
        return $self->new(items => [$self->items->@*, $item]);
    }
}

package DiscountCalculator {

    # Pure logic
    sub apply_campaign ($class, $order) {
        if ($order->total >= 5000) {
            return 0.9;    # 10% off
        }
        return 1.0;
    }
}

# --- Imperative Shell ---
package OrderShell {
    use Moo;

    has repository => (is => 'ro');    # Mock DB

    sub add_item_to_order ($self, $order_id, $item) {

        # 1. I/O: Load Data
        my $data  = $self->repository->load($order_id);
        my $order = OrderCore->new(items => $data->{items});

        # 2. Functional Core: Logic
        my $new_order = $order->with_item($item);
        my $rate      = DiscountCalculator->apply_campaign($new_order);

        # 3. I/O: Save Data & Result
        $self->repository->save(
            $order_id,
            {
                items       => $new_order->items,
                final_price => $new_order->total * $rate
            }
        );

        return $new_order;
    }
}

# --- Test ---
package MockRepo {
    use Moo;
    has store => (is => 'ro', default => sub { {} });
    sub load ($self, $id)        { return $self->store->{$id} // {items => []} }
    sub save ($self, $id, $data) { $self->store->{$id} = $data }
}

subtest 'FCIS Flow' => sub {
    my $repo  = MockRepo->new;
    my $shell = OrderShell->new(repository => $repo);

    # Step 1: Add item (Total 3000 -> No discount)
    $shell->add_item_to_order(1, {name => 'A', price => 3000});
    is $repo->store->{1}{final_price}, 3000, 'First item added';

    # Step 2: Add item (Total 6000 -> Discount applied)
    $shell->add_item_to_order(1, {name => 'B', price => 3000});

    # Total 6000 * 0.9 = 5400
    is $repo->store->{1}{final_price}, 5400, 'Discount applied at boundary';
};

done_testing;
