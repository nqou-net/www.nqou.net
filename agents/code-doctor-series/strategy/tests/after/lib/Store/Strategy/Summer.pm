package Store::Strategy::Summer;
use v5.36;
use parent 'Store::Strategy::Role';

sub new ($class) { bless {}, $class }

sub apply_discount ($self, $price, $item, $context) {

    # Summer Logic
    if ($item->{category} eq 'FOOD') {

        # Food is generally excluded, unless coupon provided
        if (defined $context->coupon_code && $context->coupon_code eq 'SUMMER_FOOD') {
            return $price * 0.95;
        }
        return $price;
    }

    # Non-Food: Rank based discount
    my $rank = $context->member_rank;

    if ($rank eq 'GOLD') {
        return $price * 0.80;    # 20% OFF
    }
    elsif ($rank eq 'SILVER') {
        return $price * 0.90;    # 10% OFF
    }
    else {
        return $price * 0.95;    # 5% OFF
    }
}

1;
