package Store::Strategy::Normal;
use v5.36;
use parent 'Store::Strategy::Role';

sub new ($class) { bless {}, $class }

sub apply_discount ($self, $price, $item, $context) {

    # Normal Logic
    if ($context->member_rank eq 'GOLD') {
        return $price * 0.98;    # 2% OFF for Gold members always
    }
    return $price;
}

1;
