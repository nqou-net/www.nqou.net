use v5.36;
use Test::More;
use List::Util      qw(sum0);
use Types::Standard qw(Int Str ArrayRef InstanceOf);

# --- 1. Immutable Data (The Contract) ---
package Order {
    use Moo;
    use Types::Standard qw(Int ArrayRef Dict Str);
    use List::Util      qw(sum0);

    has id => (is => 'ro', isa => Int, required => 1);
    has lines => (is => 'ro', isa => ArrayRef [Dict [product => Str, price => Int]], default => sub { [] });

    sub total ($self) {
        sum0(map { $_->{price} } $self->lines->@*);
    }

    sub with_line ($self, $line) {
        $self->new(id => $self->id, lines => [$self->lines->@*, $line]);
    }
}

# --- 2. Functional Core (The Brain) ---
package OrderLogic {

    # Pure functions only
    sub apply_discount ($class, $order) {
        my $total = $order->total;
        return $total >= 1000 ? int($total * 0.9) : $total;
    }
}

# --- 3. Imperative Shell (The Interface) ---
package OrderController {
    use Moo;

    has repo => (is => 'ro');    # DB Mock

    sub add_product ($self, $order_id, $product_name, $price) {

        # Phase 1: IO (Read)
        my $order = $self->repo->find($order_id);

        # Phase 2: Logic (Core)
        my $new_order   = $order->with_line({product => $product_name, price => $price});
        my $final_price = OrderLogic->apply_discount($new_order);

        # Phase 3: IO (Write)
        $self->repo->save($new_order);

        return {order => $new_order, final_price => $final_price};
    }
}

# --- 4. Tests (The Verification) ---
package InMemoryRepo {
    use Moo;
    has store => (is => 'ro', default => sub { {} });

    sub find ($self, $id) {
        return $self->store->{$id} // Order->new(id => $id);
    }

    sub save ($self, $order) {
        $self->store->{$order->id} = $order;
    }
}

subtest 'Complete Hybrid Flow' => sub {
    my $repo       = InMemoryRepo->new;
    my $controller = OrderController->new(repo => $repo);

    # 1. Add small item (no discount)
    my $res1 = $controller->add_product(1, 'Apple', 100);
    is $res1->{order}->total, 100;
    is $res1->{final_price},  100;

    # 2. Add expensive item (triggers discount > 1000)
    my $res2 = $controller->add_product(1, 'Gold', 1000);
    is $res2->{order}->total, 1100;    # 100 + 1000
    is $res2->{final_price},  990;     # 1100 * 0.9 = 990 (Int)

    # 3. Persistence Check
    my $saved = $repo->find(1);
    is $saved->total, 1100, 'State correctly persisted via Immutable updates';
};

done_testing;
