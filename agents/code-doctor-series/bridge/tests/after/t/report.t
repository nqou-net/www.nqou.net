use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ReportFormatter::CSV;
use ReportFormatter::HTML;
use ReportFormatter::Text;
use DepartmentReport::Sales;
use DepartmentReport::Accounting;
use DepartmentReport::HR;

# --- テストデータ ---
my @sales_data = ({amount => 1000, won => 3, total => 5}, {amount => 2000, won => 2, total => 5},);
my @acct_data  = ({income => 5000, expense => 3000}, {income => 2000, expense => 1000},);
my @hr_data    = ({years => 5, count => 10, resigned => 2}, {years => 3, count => 10, resigned => 1},);

# === 営業部 × 各形式 ===
subtest 'Sales + CSV' => sub {
    my $report = DepartmentReport::Sales->new(formatter => ReportFormatter::CSV->new,);
    my $out    = $report->generate(\@sales_data);
    like($out, qr/売上合計,3000/,  'CSV: total sales');
    like($out, qr/成約率,50\.0%/, 'CSV: win rate');
};

subtest 'Sales + HTML' => sub {
    my $report = DepartmentReport::Sales->new(formatter => ReportFormatter::HTML->new,);
    my $out    = $report->generate(\@sales_data);
    like($out, qr/<h1>営業部レポート<\/h1>/, 'HTML: heading');
    like($out, qr/3000/,              'HTML: total sales');
};

subtest 'Sales + Text' => sub {
    my $report = DepartmentReport::Sales->new(formatter => ReportFormatter::Text->new,);
    my $out    = $report->generate(\@sales_data);
    like($out, qr/=== 営業部レポート ===/, 'Text: heading');
    like($out, qr/3000/,            'Text: total sales');
};

# === 経理部 × CSV ===
subtest 'Accounting + CSV' => sub {
    my $report = DepartmentReport::Accounting->new(formatter => ReportFormatter::CSV->new,);
    my $out    = $report->generate(\@acct_data);
    like($out, qr/収入,7000/, 'CSV: income');
    like($out, qr/収支,3000/, 'CSV: balance');
};

# === 人事部 × HTML ===
subtest 'HR + HTML' => sub {
    my $report = DepartmentReport::HR->new(formatter => ReportFormatter::HTML->new,);
    my $out    = $report->generate(\@hr_data);
    like($out, qr/<h1>人事部レポート<\/h1>/, 'HTML: heading');
    like($out, qr/0\.4/,              'HTML: avg years');
    like($out, qr/15\.0%/,            'HTML: turnover rate');
};

# === Bridge の本領: 新しい組合せも自由自在 ===
subtest 'HR + Text (new combination)' => sub {
    my $report = DepartmentReport::HR->new(formatter => ReportFormatter::Text->new,);
    my $out    = $report->generate(\@hr_data);
    like($out, qr/=== 人事部レポート ===/, 'Text: heading');
    like($out, qr/離職率/,             'Text: turnover label');
};

subtest 'Accounting + HTML (another combination)' => sub {
    my $report = DepartmentReport::Accounting->new(formatter => ReportFormatter::HTML->new,);
    my $out    = $report->generate(\@acct_data);
    like($out, qr/<h1>経理部レポート<\/h1>/, 'HTML: heading');
    like($out, qr/収支/,                'HTML: balance label');
};

done_testing;
