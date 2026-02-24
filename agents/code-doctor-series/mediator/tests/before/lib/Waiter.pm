package Waiter;
use v5.36;

sub new($class, %args) {
    return bless {
        name     => $args{name} // 'ウェイター',
        kitchen  => $args{kitchen},
        bar      => $args{bar},
        cashier  => $args{cashier},
        # TODO: デリバリー対応... ここにも追加しなきゃ...
    }, $class;
}

sub name($self) { $self->{name} }

# 注文を受けて各セクションに直接伝える
# （全部のセクションを知っていないと動かない）
sub take_order($self, $order) {
    my @results;

    if ($order->{type} eq 'food') {
        push @results, $self->{kitchen}->prepare($order);
    }
    elsif ($order->{type} eq 'drink') {
        push @results, $self->{bar}->prepare($order);
    }
    elsif ($order->{type} eq 'both') {
        push @results, $self->{kitchen}->prepare($order);
        push @results, $self->{bar}->prepare($order);
    }

    # 会計にも直接通知
    $self->{cashier}->add_to_bill($order);

    return \@results;
}

1;
