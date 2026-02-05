package Monster;
use v5.36;
use experimental qw( builtin );
use builtin qw( true false );

sub new ($class, %args) {
    bless { %args }, $class;
}

sub clone ($self) {
    # Shallow copy is usually enough for simple cases
    # For deep copy, use Clone::clone or Storable::dclone
    my $clone = { %$self };
    bless $clone, ref $self;
}

sub x ($self, $val = undef) {
    $self->{x} = $val if defined $val;
    $self->{x};
}

sub y ($self, $val = undef) {
    $self->{y} = $val if defined $val;
    $self->{y};
}

1;
