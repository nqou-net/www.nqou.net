package DepartmentReport::Accounting;
use v5.36;
use parent 'DepartmentReport';

sub title ($self) {'経理部レポート'}

sub aggregate ($self, $data) {
    my $income  = 0;
    my $expense = 0;

    for my $row ($data->@*) {
        $income  += $row->{income}  // 0;
        $expense += $row->{expense} // 0;
    }

    my $balance = $income - $expense;

    return [['収入', $income], ['支出', $expense], ['収支', $balance],];
}

1;
