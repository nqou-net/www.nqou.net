package Dashboard::DataSource::Real;
use v5.36;
use parent 'Dashboard::DataSource';

use DBI;
use HTTP::Tiny;
use JSON::PP qw(decode_json);

my $DSN  = "dbi:SQLite:dbname=dashboard.db";
my $USER = "";
my $PASS = "";

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{http} = HTTP::Tiny->new(timeout => 5);
    return $self;
}

sub fetch_sales_summary ($self, $year, $month) {
    my $dbh = DBI->connect($DSN, $USER, $PASS, {RaiseError => 1});
    my $rows
        = $dbh->selectall_arrayref("SELECT product, SUM(amount) as total FROM sales WHERE year=? AND month=? GROUP BY product", {Slice => {}}, $year, $month);
    $dbh->disconnect;
    return $rows;
}

sub fetch_exchange_rate ($self, $currency) {
    my $res = $self->{http}->get("https://api.exchange.example.com/latest?base=JPY&symbols=$currency");
    die "API error: $res->{status}" unless $res->{success};
    my $data = decode_json($res->{content});
    return $data->{rates}{$currency};
}

1;
