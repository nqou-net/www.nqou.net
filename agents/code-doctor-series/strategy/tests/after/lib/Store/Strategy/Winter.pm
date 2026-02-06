package Store::Strategy::Winter;
use v5.36;
use parent 'Store::Strategy::Role';

sub new ($class) { bless {}, $class }

sub apply_discount ($self, $price, $item, $context) {

    # Winter Logic
    if ($item->{category} eq 'ELECTRONICS') {
        $price *= 0.90;    # 10% OFF base for electronics

        if ($context->member_rank eq 'GOLD') {
            $price -= 500;    # Extra 500 off
        }
        return $price;
    }

    return $price;
}

1;
