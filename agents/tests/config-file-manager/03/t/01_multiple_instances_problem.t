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
$config->set('debug', 0);

my $logger_config = Config->new();
$logger_config->load_config("$FindBin::Bin/../data/config.ini");

ok !$config->get('debug'), 'main config debug disabled';
ok $logger_config->get('debug'), 'logger config still enabled (problem reproduced)';

is scalar @warnings, 0, 'no warnings';

done_testing;
