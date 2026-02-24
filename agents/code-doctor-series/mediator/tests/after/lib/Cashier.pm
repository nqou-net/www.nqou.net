package Cashier;
use v5.36;
use Section;
use parent 'Section';

sub new($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{name} //= '会計';
    $self->{bills} = {};
    return $self;
}

# 注文を伝票に追加（他のセクションには一切触れない）
sub add_to_bill($self, $order) {
    my $table = $order->{table} // 'unknown';
    $self->{bills}{$table} //= [];
    push $self->{bills}{$table}->@*, $order->{item} // '不明';
    return "Cashier: テーブル${table}に追加";
}

# 会計（精算）
sub checkout($self, $table) {
    my $items = $self->{bills}{$table} // [];
    my $count = scalar $items->@*;
    delete $self->{bills}{$table};
    return "Cashier: テーブル${table} ${count}品のお会計完了";
}

1;
