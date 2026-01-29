use v5.36;
use Test::More;
use builtin qw(true false);
no warnings 'experimental::builtin';

# --- Functional Core (Pure) ---
package CoreCalculator {

    sub calculate_total ($class, $items) {
        my $total = 0;
        $total += $_->{price} for $items->@*;
        return $total;
    }
}

# --- Imperative Shell (Side Effects) ---
package ShellService {
    use Moo;

    sub fetch_and_calculate ($self) {

        # Imagine this calls a DB
        my $items = [{price => 100}, {price => 200}];
        return CoreCalculator->calculate_total($items);
    }
}

subtest 'Unit Test (Core)' => sub {

    # No mocks needed! Just data in, data out.
    my $items = [{price => 100}, {price => 200}, {price => 300},];
    is CoreCalculator->calculate_total($items), 600, 'Core logic is correct';
};

subtest 'Integration Test (Shell)' => sub {

    # Checking if the wiring is correct
    my $service = ShellService->new;
    is $service->fetch_and_calculate(), 300, 'Shell wires data to Core correctly';
};

done_testing;
