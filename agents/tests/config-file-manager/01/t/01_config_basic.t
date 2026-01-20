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

is $config->app_name, 'MyApp', 'default app_name';
is $config->version, '1.0.0', 'default version';
ok $config->debug, 'default debug enabled';

my $custom_config = Config->new(debug => 0);
ok !$custom_config->debug, 'debug can be overridden';

is scalar @warnings, 0, 'no warnings';

done_testing;
