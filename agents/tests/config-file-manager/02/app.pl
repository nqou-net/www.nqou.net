use v5.36;
use Moo;

package Config {
    use Moo;

    has _settings => (is => 'ro', default => sub { {} });

    sub load_config ($self, $file) {
        open my $fh, '<', $file or die "Cannot open $file: $!";
        while (my $line = <$fh>) {
            chomp $line;
            next if $line =~ /^\s*$/;
            next if $line =~ /^\s*#/;

            if ($line =~ /^\s*(\w+)\s*=\s*(.+?)\s*$/) {
                my ($key, $value) = ($1, $2);
                $self->set($key, $value);
            }
        }
        close $fh;
    }

    sub set ($self, $key, $value) {
        $self->_settings->{$key} = $value;
    }

    sub get ($self, $key) {
        return $self->_settings->{$key};
    }
};

package main;

unless (caller) {
    my $config = Config->new();
    $config->load_config('config.ini');

    say "アプリ名: " . $config->get('app_name');
    say "バージョン: " . $config->get('version');
    say "デバッグモード: " . ($config->get('debug') ? 'ON' : 'OFF');
}

1;
