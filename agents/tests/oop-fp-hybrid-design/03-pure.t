use v5.36;
use Test::More;
use builtin qw(true false);
no warnings 'experimental::builtin';

package OrderCalculator {

    # Pure Function: No side effects, depends only on input
    sub calculate_discount ($class, $total, $rate) {
        return $total * (1 - $rate);
    }

    # Pure Function: Validation logic
    sub is_eligible_for_campaign ($class, $total) {
        return $total >= 5000 ? true : false;
    }
}

package OrderService {
    use Moo;
    use Test::More;    # Explicitly import for 'note'

    # Mocking external dependency
    sub logger ($self, $msg) { note "LOG: $msg" }

    sub process_discount ($self, $order) {

        # Side effects (logging) are here
        $self->logger("Calculating discount for order");

        # Logic is delegated to Pure Function
        my $new_total = OrderCalculator->calculate_discount($order->{total}, 0.1);

        return $new_total;
    }
}

subtest 'Pure Function Logic' => sub {

    # Testing logic without any mocking!
    is OrderCalculator->calculate_discount(1000, 0.1),  900,   'Discount calculation is correct';
    is OrderCalculator->is_eligible_for_campaign(5000), true,  'Campaign eligibility (true)';
    is OrderCalculator->is_eligible_for_campaign(4999), false, 'Campaign eligibility (false)';
};

subtest 'Integration with Shell' => sub {
    my $service = OrderService->new;
    my $order   = {total => 1000};

    is $service->process_discount($order), 900, 'Service delegates correctly';
};

done_testing;
