use v5.36;
use Test::More;
use Test::Exception;

package TypedOrder {
    use Moo;
    use Types::Standard qw(Int Str ArrayRef Dict Optional);

    # Validation at the boundary
    has id => (is => 'ro', isa => Int, required => 1);

    has items => (
        is  => 'ro',
        isa => ArrayRef [
            Dict [
                name  => Str,
                price => Int,
                qty   => Optional [Int]
            ]
        ],
        default => sub { [] }
    );

    sub add_item ($self, $item) {

        # Type check happens here automatically if we constructed a new object with validation
        # But for method arguments, we might checking manually or let the constructor of the new object handle it
        return $self->new(
            id    => $self->id,
            items => [$self->items->@*, $item]
        );
    }
}

subtest 'Type Validation' => sub {
    lives_ok {
        TypedOrder->new(id => 1, items => [{name => 'A', price => 100}]);
    }
    'Valid data passes';

    dies_ok {
        TypedOrder->new(id => 'invalid', items => []);
    }
    'Invalid ID (String instead of Int) fails';

    dies_ok {
        TypedOrder->new(id => 2, items => [{name => 'B', price => 'expensive'}]);
    }
    'Invalid Item Price (String instead of Int) fails';
};

done_testing;
