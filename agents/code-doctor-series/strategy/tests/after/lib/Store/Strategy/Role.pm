package Store::Strategy::Role;
use v5.36;

# Interface definition
sub apply_discount ($self, $price, $item, $context) {
    die "Method 'apply_discount' must be implemented by subclass";
}

1;
