package PawsHeart::Animal::Dog;
use v5.36;

sub new ($class, %args) {
    return bless {
        name   => $args{name}   // 'Unknown',
        breed  => $args{breed}  // 'Mixed',
        weight => $args{weight} // 0,
    }, $class;
}

sub name   ($self) { $self->{name} }
sub breed  ($self) { $self->{breed} }
sub weight ($self) { $self->{weight} }

1;
