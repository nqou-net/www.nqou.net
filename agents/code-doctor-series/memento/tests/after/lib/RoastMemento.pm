package RoastMemento;
use v5.36;
use Storable 'dclone';

sub new($class, $state, $label = '') {
    bless {
        state     => dclone($state),
        label     => $label,
        timestamp => time(),
    }, $class;
}

sub state($self)     { dclone($self->{state}) }
sub label($self)     { $self->{label} }
sub timestamp($self) { $self->{timestamp} }

1;
