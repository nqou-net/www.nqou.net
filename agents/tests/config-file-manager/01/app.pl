use v5.36;
use Moo;

package Config {
    use Moo;

    has app_name => (is => 'ro', default => sub { 'MyApp' });
    has version  => (is => 'ro', default => sub { '1.0.0' });
    has debug    => (is => 'ro', default => sub { 1 });
};

package main;

unless (caller) {
    my $config = Config->new();

    say "アプリ名: " . $config->app_name;
    say "バージョン: " . $config->version;
    say "デバッグモード: " . ($config->debug ? 'ON' : 'OFF');
}

1;
