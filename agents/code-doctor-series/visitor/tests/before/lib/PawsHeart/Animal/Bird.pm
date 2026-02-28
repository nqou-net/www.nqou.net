package PawsHeart::Animal::Bird;
use v5.36;

sub new ($class, %args) {
    return bless {
        name    => $args{name}    // 'Unknown',
        species => $args{species} // 'Unknown',
        can_fly => $args{can_fly} // 1,
    }, $class;
}

sub name    ($self) { $self->{name} }
sub species ($self) { $self->{species} }
sub can_fly ($self) { $self->{can_fly} }

1;
