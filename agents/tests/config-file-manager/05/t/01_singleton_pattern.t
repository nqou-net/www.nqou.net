use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}
use FindBin;

require "$FindBin::Bin/../app.pl";

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $config = Config->instance();
$config->load_config("$FindBin::Bin/../data/config.ini");

$config->set('debug', 0);

my $logger = Logger->new();

my $config_again = Config->instance();

is $config_again, $config, 'instance returns same object';
ok !$config_again->get('debug'), 'debug change is shared';

is scalar @warnings, 0, 'no warnings';

done_testing;
