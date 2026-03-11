package Before::OrderService;
use Moo;

sub process_order {
    my ($self, $user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token) = @_;
    # 呼び出し元。下層のためにただ引き回す
    return $self->validate_order($user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token);
}

sub validate_order {
    my ($self, $user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token) = @_;
    
    die "Invalid auth token" unless $auth_token eq 'secret_token';
    die "Invalid amount" if $amount <= 0;

    # 💥ここで悲劇が起きる！ user_id と shop_id の順番を間違えている！
    return $self->calculate_discount($shop_id, $user_id, $item_id, $amount, $campaign_code);
}

sub calculate_discount {
    my ($self, $user_id, $shop_id, $item_id, $amount, $campaign_code) = @_;
    
    # 順番を間違えたため、$user_id に $shop_id が入ってしまっている
    # 疑似的にDB検索を模する
    my $user_is_premium = ($user_id == 1) ? 1 : 0;
    
    my $discount = 0;
    if ($campaign_code && $campaign_code eq 'SUMMER') {
        $discount = 500;
    }
    if ($user_is_premium) {
        $discount += $amount * 0.1;
    }
    
    return $amount - $discount;
}

1;
