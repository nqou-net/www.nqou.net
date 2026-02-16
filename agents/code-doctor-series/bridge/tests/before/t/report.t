use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Report;

# --- 営業部テスト ---
my @sales_data = ({amount => 1000, won => 3, total => 5}, {amount => 2000, won => 2, total => 5},);

my $csv_sales = Report::generate_report('sales', 'csv', \@sales_data);
like($csv_sales, qr/3000/,   'Sales CSV contains total sales');
like($csv_sales, qr/50\.0%/, 'Sales CSV contains win rate');

my $html_sales = Report::generate_report('sales', 'html', \@sales_data);
like($html_sales, qr/<h1>営業部レポート<\/h1>/, 'Sales HTML has heading');
like($html_sales, qr/3000/,              'Sales HTML contains total sales');

my $text_sales = Report::generate_report('sales', 'text', \@sales_data);
like($text_sales, qr/=== 営業部レポート ===/, 'Sales text has heading');

# --- 経理部テスト ---
my @acct_data = ({income => 5000, expense => 3000}, {income => 2000, expense => 1000},);

my $csv_acct = Report::generate_report('accounting', 'csv', \@acct_data);
like($csv_acct, qr/7000/, 'Accounting CSV contains income');
like($csv_acct, qr/3000/, 'Accounting CSV contains balance');

my $text_acct = Report::generate_report('accounting', 'text', \@acct_data);
like($text_acct, qr/収支: 3000/, 'Accounting text contains balance');

# --- 人事部テスト ---
my @hr_data = ({years => 5, count => 10, resigned => 2}, {years => 3, count => 10, resigned => 1},);

my $csv_hr = Report::generate_report('hr', 'csv', \@hr_data);
like($csv_hr, qr/0\.4/,   'HR CSV contains avg years');
like($csv_hr, qr/15\.0%/, 'HR CSV contains turnover rate');

my $html_hr = Report::generate_report('hr', 'html', \@hr_data);
like($html_hr, qr/<h1>人事部レポート<\/h1>/, 'HR HTML has heading');

done_testing;
