package Report;
use v5.36;

# TODO: 新しい部門や形式が増えるたびにここを触る
# ……もう何が何だか分からなくなってきた（by ミサキ）

sub generate_report ($department, $format, $data) {
    my $output = "";

    if ($department eq 'sales') {
        # 営業部のロジック: 売上合計と成約率を計算
        my $total_sales = 0;
        my $deals_won   = 0;
        my $deals_total = 0;
        for my $row ($data->@*) {
            $total_sales += $row->{amount}  // 0;
            $deals_won   += $row->{won}     // 0;
            $deals_total += $row->{total}   // 0;
        }
        my $win_rate = $deals_total > 0
            ? sprintf("%.1f", $deals_won / $deals_total * 100)
            : "0.0";

        if ($format eq 'csv') {
            $output  = "部門,売上合計,成約率\n";
            $output .= "営業,$total_sales,${win_rate}%\n";
        }
        elsif ($format eq 'html') {
            $output  = "<html><body><h1>営業部レポート</h1>\n";
            $output .= "<table><tr><th>売上合計</th><td>$total_sales</td></tr>\n";
            $output .= "<tr><th>成約率</th><td>${win_rate}%</td></tr></table>\n";
            $output .= "</body></html>\n";
        }
        elsif ($format eq 'text') {
            $output  = "=== 営業部レポート ===\n";
            $output .= "売上合計: $total_sales\n";
            $output .= "成約率:   ${win_rate}%\n";
        }
        else {
            die "未対応の形式: $format";
        }
    }
    elsif ($department eq 'accounting') {
        # 経理部のロジック: 収支バランスを計算
        my $income  = 0;
        my $expense = 0;
        for my $row ($data->@*) {
            $income  += $row->{income}  // 0;
            $expense += $row->{expense} // 0;
        }
        my $balance = $income - $expense;

        if ($format eq 'csv') {
            $output  = "部門,収入,支出,収支\n";
            $output .= "経理,$income,$expense,$balance\n";
        }
        elsif ($format eq 'html') {
            $output  = "<html><body><h1>経理部レポート</h1>\n";
            $output .= "<table><tr><th>収入</th><td>$income</td></tr>\n";
            $output .= "<tr><th>支出</th><td>$expense</td></tr>\n";
            $output .= "<tr><th>収支</th><td>$balance</td></tr></table>\n";
            $output .= "</body></html>\n";
        }
        elsif ($format eq 'text') {
            $output  = "=== 経理部レポート ===\n";
            $output .= "収入: $income\n";
            $output .= "支出: $expense\n";
            $output .= "収支: $balance\n";
        }
        else {
            die "未対応の形式: $format";
        }
    }
    elsif ($department eq 'hr') {
        # 人事部のロジック: 平均勤続年数と離職率
        my $total_years = 0;
        my $headcount   = 0;
        my $resigned    = 0;
        for my $row ($data->@*) {
            $total_years += $row->{years}    // 0;
            $headcount   += $row->{count}    // 0;
            $resigned    += $row->{resigned} // 0;
        }
        my $avg_years     = $headcount > 0
            ? sprintf("%.1f", $total_years / $headcount)
            : "0.0";
        my $turnover_rate = $headcount > 0
            ? sprintf("%.1f", $resigned / $headcount * 100)
            : "0.0";

        if ($format eq 'csv') {
            $output  = "部門,平均勤続年数,離職率\n";
            $output .= "人事,$avg_years,${turnover_rate}%\n";
        }
        elsif ($format eq 'html') {
            $output  = "<html><body><h1>人事部レポート</h1>\n";
            $output .= "<table><tr><th>平均勤続年数</th><td>$avg_years</td></tr>\n";
            $output .= "<tr><th>離職率</th><td>${turnover_rate}%</td></tr></table>\n";
            $output .= "</body></html>\n";
        }
        elsif ($format eq 'text') {
            $output  = "=== 人事部レポート ===\n";
            $output .= "平均勤続年数: $avg_years\n";
            $output .= "離職率:       ${turnover_rate}%\n";
        }
        else {
            die "未対応の形式: $format";
        }
    }
    else {
        die "未対応の部門: $department";
    }

    return $output;
}

1;
