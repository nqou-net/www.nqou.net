package ExpenseRequest;
use v5.36;
use parent 'AbstractRequest';

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{amount}   //= die "金額は必須です";
    $self->{category} //= die "経費カテゴリは必須です";
    return $self;
}

sub validate_input ($self) {
    die "金額は正の数である必要があります"
        unless $self->{amount} > 0;
    my @valid = qw(交通費 宿泊費 交際費 消耗品費 通信費);
    die "無効な経費カテゴリ: $self->{category}"
        unless grep { $_ eq $self->{category} } @valid;
    return 1;
}

sub check_budget ($self) {
    my $remaining = _get_department_budget($self->{applicant});
    if ($self->{amount} > $remaining) {
        $self->{status} = 'rejected';
        die "予算超過";
    }
    return 1;
}

sub route_approval ($self) {
    push $self->{approved_by}->@*, '課長';
    push $self->{approved_by}->@*, '部長' if $self->{amount} >= 10_000;
    $self->{status} = 'approved';
    return 1;
}

sub request_type_name ($self) { return '経費精算' }

sub summary_for_log ($self) {
    return "$self->{amount}円 ($self->{category})";
}

sub _get_department_budget ($applicant) { return 500_000 }

1;
