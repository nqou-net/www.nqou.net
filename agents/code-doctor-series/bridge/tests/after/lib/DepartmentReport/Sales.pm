package DepartmentReport::Sales;
use v5.36;
use parent 'DepartmentReport';

sub title ($self) {'営業部レポート'}

sub aggregate ($self, $data) {
    my $total_sales = 0;
    my $deals_won   = 0;
    my $deals_total = 0;

    for my $row ($data->@*) {
        $total_sales += $row->{amount} // 0;
        $deals_won   += $row->{won}    // 0;
        $deals_total += $row->{total}  // 0;
    }

    my $win_rate
        = $deals_total > 0
        ? sprintf("%.1f%%", $deals_won / $deals_total * 100)
        : "0.0%";

    return [['売上合計', $total_sales], ['成約率', $win_rate],];
}

1;
