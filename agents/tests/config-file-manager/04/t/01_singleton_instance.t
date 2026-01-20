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

my $logger_config = Config->instance();

is $logger_config, $config, 'instance returns same object';
ok !$logger_config->get('debug'), 'debug change is shared';

is scalar @warnings, 0, 'no warnings';

done_testing;
