package Bad::File;
use v5.36;
use experimental qw(builtin);

sub new ($class, %args) {
    bless {name => $args{name}, size => $args{size} // 100}, $class;
}

sub name ($self) { $self->{name} }
sub size ($self) { $self->{size} }

sub copy_to ($self, $dest) {

    # 実際にはコピーせずログだけ
    "Copying file " . $self->name . " to $dest";
}

1;
