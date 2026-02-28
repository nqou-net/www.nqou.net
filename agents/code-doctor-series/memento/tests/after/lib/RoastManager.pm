package RoastManager;
use v5.36;
use Storable 'dclone';
use RoastMemento;

sub new($class) {
    bless {
        profile => {
            temp_start  => 180,
            temp_peak   => 220,
            duration    => 720,    # 秒
            fan_speed   => 65,     # %
            bean_type   => 'Ethiopia Yirgacheffe',
        },
    }, $class;
}

sub profile($self) {
    return $self->{profile};
}

sub update_profile($self, %params) {
    $self->{profile}{$_} = $params{$_} for keys %params;
}

# --- Memento 対応 ---

sub save_to_memento($self, $label = '') {
    RoastMemento->new($self->{profile}, $label);
}

sub restore_from_memento($self, $memento) {
    $self->{profile} = $memento->state;
}

1;
