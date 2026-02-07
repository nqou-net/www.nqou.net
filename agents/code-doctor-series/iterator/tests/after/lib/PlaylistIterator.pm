package PlaylistIterator;
use v5.36;
use parent 'Iterator';

sub new($class, $songs) {
    bless {
        songs => $songs,
        index => 0,
    }, $class;
}

sub has_next($self) {
    return $self->{index} < $self->{songs}->@*;
}

sub next($self) {
    return $self->{songs}->[$self->{index}++];
}

1;
