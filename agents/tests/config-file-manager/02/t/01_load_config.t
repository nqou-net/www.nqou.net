use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}
use FindBin;

require "$FindBin::Bin/../app.pl";

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $config = Config->new();
$config->load_config("$FindBin::Bin/../data/config.ini");

is $config->get('app_name'), 'MyApp', 'app_name loaded';
is $config->get('version'), '1.0.0', 'version loaded';
is $config->get('debug'), '1', 'debug loaded as string';

$config->set('debug', 0);

is $config->get('debug'), 0, 'debug value can be updated';

is scalar @warnings, 0, 'no warnings';

done_testing;
