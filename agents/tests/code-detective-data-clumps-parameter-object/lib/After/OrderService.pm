package After::OrderService;
use Moo;

sub process_order {
    my ($self, $context) = @_;
    return $self->validate_order($context);
}

sub validate_order {
    my ($self, $context) = @_;
    
    die "Invalid auth token" unless $context->auth_token eq 'secret_token';
    die "Invalid amount" if $context->amount <= 0;

    return $self->calculate_discount($context);
}

sub calculate_discount {
    my ($self, $context) = @_;
    
    # 疑似的にDB検索を模する
    my $user_is_premium = ($context->user_id == 1) ? 1 : 0;
    
    my $discount = 0;
    if (my $campaign_code = $context->campaign_code) {
        if ($campaign_code eq 'SUMMER') {
            $discount = 500;
        }
    }
    if ($user_is_premium) {
        $discount += $context->amount * 0.1;
    }
    
    return $context->amount - $discount;
}

1;
