package Bad::Directory;
use v5.36;

sub new ($class, %args) {
    bless {name => $args{name}, children => []}, $class;
}

sub name ($self) { $self->{name} }

sub add ($self, $child) {
    push @{$self->{children}}, $child;
}

sub children ($self) {
    @{$self->{children}};
}

sub make_new ($self, $path) {
    "Creating directory " . $self->name . " at $path";
}

1;
