package Role::Subject;
use v5.36;

sub observers ($self) {
    $self->{_observers} //= [];
}

sub add_observer ($self, $observer) {
    push $self->observers->@*, $observer;
}

sub notify_observers ($self) {
    for my $observer ($self->observers->@*) {
        $observer->update($self);
    }
}

1;
