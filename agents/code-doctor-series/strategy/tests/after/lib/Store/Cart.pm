package Store::Cart;
use v5.36;
use Store::Strategy::Factory;

sub new ($class, %args) {
    my $self = bless {
        items       => [],
        campaign_id => $args{campaign_id},
        member_rank => $args{member_rank} // 'BRONZE',
        coupon_code => $args{coupon_code},
        today       => $args{today},
    }, $class;

    # Initialize Strategy
    # In a real app, this might be injected, but here we use a Factory based on input
    $self->{strategy} = Store::Strategy::Factory->create($self->{campaign_id});

    return $self;
}

# Accessors for Strategy use
sub member_rank ($self) { $self->{member_rank} }
sub coupon_code ($self) { $self->{coupon_code} }

sub add_item ($self, $name, $price, $category) {
    push $self->{items}->@*, {name => $name, price => $price, category => $category};
}

sub calculate_total ($self) {
    my $total = 0;

    for my $item ($self->{items}->@*) {
        my $price = $item->{price};

        # Delegate to Strategy
        $price = $self->{strategy}->apply_discount($price, $item, $self);

        # 5th Day Rule (Global Policy)
        # Demonstrates that some logic can remain if it's not part of the varied strategy
        if (defined $self->{today} && $self->{today} =~ /-(?:05|15|25)$/) {
            $price -= 100 if $price >= 1000;
        }

        # Safety check
        $price = 0 if $price < 0;

        $total += $price;
    }

    return int($total);
}

1;
