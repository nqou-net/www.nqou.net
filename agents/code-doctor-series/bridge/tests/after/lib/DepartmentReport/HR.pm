package DepartmentReport::HR;
use v5.36;
use parent 'DepartmentReport';

sub title ($self) {'人事部レポート'}

sub aggregate ($self, $data) {
    my $total_years = 0;
    my $headcount   = 0;
    my $resigned    = 0;

    for my $row ($data->@*) {
        $total_years += $row->{years}    // 0;
        $headcount   += $row->{count}    // 0;
        $resigned    += $row->{resigned} // 0;
    }

    my $avg_years
        = $headcount > 0
        ? sprintf("%.1f", $total_years / $headcount)
        : "0.0";
    my $turnover_rate
        = $headcount > 0
        ? sprintf("%.1f%%", $resigned / $headcount * 100)
        : "0.0%";

    return [['平均勤続年数', $avg_years], ['離職率', $turnover_rate],];
}

1;
