package TestDataBuilder::Order;
use v5.36;
use Moo;
with 'Role::Builder';

has _overrides => (is => 'ro', default => sub { {} });
has _items     => (is => 'ro', default => sub { [] });

sub _defaults($self) {
    return {
        id          => 5001,
        user_id     => 1001,
        total_price => 3000,
        status      => 'pending',
        ordered_at  => '2025-06-15T10:30:00+09:00',
        items       => [
            {
                product_id => 101,
                name       => 'Perlクックブック',
                price      => 3000,
                quantity   => 1,
            },
        ],
        shipping => {
            zipcode => '150-0001',
            address => '東京都渋谷区神宮前1-1-1',
            method  => 'standard',
        },
    };
}

sub with_id($self, $id)             { $self->_with(id => $id) }
sub with_user_id($self, $user_id)   { $self->_with(user_id => $user_id) }
sub with_total($self, $total)       { $self->_with(total_price => $total) }
sub with_status($self, $status)     { $self->_with(status => $status) }

sub with_shipping($self, %args) {
    my $current = $self->_overrides->{shipping} // {};
    return (ref $self)->new(
        _overrides => {
            $self->_overrides->%*,
            shipping => { $current->%*, %args },
        },
        _items => [ $self->_items->@* ],
    );
}

sub with_items($self, @items) {
    return (ref $self)->new(
        _overrides => { $self->_overrides->%* },
        _items     => [ @items ],
    );
}

sub add_item($self, %item) {
    return (ref $self)->new(
        _overrides => { $self->_overrides->%* },
        _items     => [ $self->_items->@*, \%item ],
    );
}

sub _with($self, $key, $value) {
    return (ref $self)->new(
        _overrides => { $self->_overrides->%*, $key => $value },
        _items     => [ $self->_items->@* ],
    );
}

sub build($self) {
    my $data = $self->_merge_deep($self->_defaults, $self->_overrides);

    # カスタムアイテムが指定されていれば上書き
    if ($self->_items->@*) {
        $data->{items} = [ $self->_items->@* ];
    }

    # バリデーション
    for my $required (qw(id user_id status)) {
        die "必須フィールド '$required' が未設定です"
            unless defined $data->{$required};
    }
    die "items が空です" unless $data->{items} && $data->{items}->@*;
    die "total_price が0以下です"
        unless $data->{total_price} && $data->{total_price} > 0;

    return $data;
}

1;
