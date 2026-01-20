use v5.36;
use Moo;

package Config {
    use Moo;

    has _settings => (is => 'ro', default => sub { {} });

    sub instance ($class) {
        state $instance;
        if (!$instance) {
            $instance = $class->new();
        }
        return $instance;
    }

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

package Logger {
    use Moo;
    use v5.36;

    sub debug ($self, $message) {
        my $config = Config->instance();

        if ($config->get('debug')) {
            say "[DEBUG] $message";
        }
    }
};

package main;

my $config = Config->instance();
$config->load_config('config.ini');

say "アプリ名: " . $config->get('app_name');

$config->set('debug', 0);

say "デバッグモード（メイン側）: " . ($config->get('debug') ? 'ON' : 'OFF');

my $logger = Logger->new();
$logger->debug("処理を開始します");

say "デバッグログは出力されませんでした";
