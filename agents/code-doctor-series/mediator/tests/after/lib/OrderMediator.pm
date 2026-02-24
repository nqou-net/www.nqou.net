package OrderMediator;
use v5.36;

sub new($class, %args) {
    return bless {
        sections => {},
    }, $class;
}

# セクションを登録する（キッチン、バー、会計、デリバリーなど）
sub register($self, $name, $section) {
    $self->{sections}{$name} = $section;
    $section->set_mediator($self);
    return $self;
}

# セクション間の通知を仲介する
sub notify($self, $event, $data = {}) {
    my @results;

    if ($event eq 'food_order') {
        if (my $kitchen = $self->{sections}{kitchen}) {
            push @results, $kitchen->prepare($data);
        }
        if (my $cashier = $self->{sections}{cashier}) {
            $cashier->add_to_bill($data);
        }
    }
    elsif ($event eq 'drink_order') {
        if (my $bar = $self->{sections}{bar}) {
            push @results, $bar->prepare($data);
        }
        if (my $cashier = $self->{sections}{cashier}) {
            $cashier->add_to_bill($data);
        }
    }
    elsif ($event eq 'combo_order') {
        if (my $kitchen = $self->{sections}{kitchen}) {
            push @results, $kitchen->prepare($data);
        }
        if (my $bar = $self->{sections}{bar}) {
            push @results, $bar->prepare($data);
        }
        if (my $cashier = $self->{sections}{cashier}) {
            $cashier->add_to_bill($data);
        }
    }
    elsif ($event eq 'delivery_order') {
        if (my $kitchen = $self->{sections}{kitchen}) {
            push @results, $kitchen->prepare($data);
        }
        if (my $delivery = $self->{sections}{delivery}) {
            push @results, $delivery->dispatch($data);
        }
        if (my $cashier = $self->{sections}{cashier}) {
            $cashier->add_to_bill($data);
        }
    }
    elsif ($event eq 'ready') {
        if (my $waiter = $self->{sections}{waiter}) {
            push @results, "配膳準備: テーブル$data->{table}";
        }
    }
    elsif ($event eq 'checkout') {
        if (my $cashier = $self->{sections}{cashier}) {
            push @results, $cashier->checkout($data->{table});
        }
    }

    return \@results;
}

1;
