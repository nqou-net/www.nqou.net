package Store::Cart;
use v5.36;

sub new ($class, %args) {
    bless { 
        items       => [], 
        campaign_id => $args{campaign_id},
        member_rank => $args{member_rank} // 'BRONZE', # GOLD, SILVER, BRONZE
        coupon_code => $args{coupon_code},
        today       => $args{today},       # YYYY-MM-DD
    }, $class;
}

sub add_item ($self, $name, $price, $category) {
    push $self->{items}->@*, { name => $name, price => $price, category => $category };
}

sub calculate_total ($self) {
    my $total = 0;
    
    for my $item ($self->{items}->@*) {
        my $price = $item->{price};
        
        # Deeply nested conditional logic (The Symptom)
        if (defined $self->{campaign_id} && $self->{campaign_id} eq 'SUMMER_2026') {
            # 夏のキャンペーン：食品は対象外、ただし特定クーポンがあれば...
            if ($item->{category} eq 'FOOD') {
                 if (defined $self->{coupon_code} && $self->{coupon_code} eq 'SUMMER_FOOD') {
                     $price *= 0.95;
                 }
            } else {
                 # 食品以外はランク別割引
                 if ($self->{member_rank} eq 'GOLD') {
                     $price *= 0.80; # 20% OFF
                 } elsif ($self->{member_rank} eq 'SILVER') {
                     $price *= 0.90; # 10% OFF
                 } else {
                     $price *= 0.95; # 5% OFF
                 }
            }
        } elsif (defined $self->{campaign_id} && $self->{campaign_id} eq 'WINTER_2026') {
             # 冬のキャンペーン：家電が安い
             if ($item->{category} eq 'ELECTRONICS') {
                 $price *= 0.90;
                 if ($self->{member_rank} eq 'GOLD') {
                     $price -= 500; # さらに500円引き
                 }
             }
        } else {
             # 通常時
             if ($self->{member_rank} eq 'GOLD') {
                 $price *= 0.98; # 2% OFF
             }
        }
        
        # 5のつく日（全品対象、最後に適用）
        if (defined $self->{today} && $self->{today} =~ /-(?:05|15|25)$/) {
            $price -= 100 if $price >= 1000;
        }

        # 価格が負にならないように
        $price = 0 if $price < 0;

        $total += $price;
    }
    
    return int($total);
}

1;
