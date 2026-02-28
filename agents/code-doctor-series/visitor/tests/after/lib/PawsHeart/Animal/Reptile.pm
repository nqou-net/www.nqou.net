package PawsHeart::Animal::Reptile;
use v5.36;

sub new ($class, %args) {
    return bless {
        name        => $args{name}        // 'Unknown',
        species     => $args{species}     // 'Unknown',
        temperature => $args{temperature} // 25,
    }, $class;
}

sub name        ($self) { $self->{name} }
sub species     ($self) { $self->{species} }
sub temperature ($self) { $self->{temperature} }

sub accept ($self, $visitor) {
    $visitor->visit_reptile($self);
}

1;
