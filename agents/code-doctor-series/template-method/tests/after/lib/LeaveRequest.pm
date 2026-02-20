package LeaveRequest;
use v5.36;
use parent 'AbstractRequest';

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{start_date} //= die "開始日は必須です";
    $self->{end_date}   //= die "終了日は必須です";
    return $self;
}

sub validate_input ($self) {
    die "開始日は終了日以前である必要があります"
        unless $self->{start_date} le $self->{end_date};
    return 1;
}

sub check_budget ($self) {
    my $remaining = _get_leave_balance($self->{applicant});
    my $days      = _calc_business_days($self->{start_date}, $self->{end_date});
    if ($days > $remaining) {
        $self->{status} = 'rejected';
        die "有給残日数不足";
    }
    return 1;
}

sub route_approval ($self) {
    push $self->{approved_by}->@*, '課長';
    $self->{status} = 'approved';
    return 1;
}

sub request_type_name ($self) { return '有給休暇' }

sub summary_for_log ($self) {
    return "$self->{start_date}〜$self->{end_date}";
}

sub _get_leave_balance  ($applicant)   { return 20 }
sub _calc_business_days ($start, $end) { return 3 }

1;
