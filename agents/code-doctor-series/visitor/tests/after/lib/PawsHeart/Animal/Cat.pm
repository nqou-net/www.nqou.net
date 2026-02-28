package PawsHeart::Animal::Cat;
use v5.36;

sub new ($class, %args) {
    return bless {
        name      => $args{name}      // 'Unknown',
        breed     => $args{breed}     // 'Mixed',
        is_indoor => $args{is_indoor} // 1,
    }, $class;
}

sub name      ($self) { $self->{name} }
sub breed     ($self) { $self->{breed} }
sub is_indoor ($self) { $self->{is_indoor} }

sub accept ($self, $visitor) {
    $visitor->visit_cat($self);
}

1;
