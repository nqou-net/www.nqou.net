package EquipmentRequest;
use v5.36;
use parent 'AbstractRequest';

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{item_name}  //= die "品名は必須です";
    $self->{unit_price} //= die "単価は必須です";
    $self->{quantity}   //= 1;
    return $self;
}

sub validate_input ($self) {
    die "数量は正の整数である必要があります"
        unless $self->{quantity} > 0 && $self->{quantity} == int($self->{quantity});
    die "単価は正の数である必要があります"
        unless $self->{unit_price} > 0;
    return 1;
}

sub check_budget ($self) {
    my $total     = $self->{quantity} * $self->{unit_price};
    my $remaining = _get_department_budget($self->{applicant});
    if ($total > $remaining) {
        $self->{status} = 'rejected';
        die "予算超過";
    }
    return 1;
}

sub route_approval ($self) {
    my $total = $self->{quantity} * $self->{unit_price};
    push $self->{approved_by}->@*, '課長';
    if ($total >= 50_000) {
        push $self->{approved_by}->@*, '部長';
        push $self->{approved_by}->@*, '総務部長';
    }
    $self->{status} = 'approved';
    return 1;
}

sub request_type_name ($self) { return '備品購入' }

sub summary_for_log ($self) {
    my $total = $self->{quantity} * $self->{unit_price};
    return "$self->{item_name} x$self->{quantity} ${total}円";
}

sub _get_department_budget ($applicant) { return 500_000 }

1;
