package PointService::Decorator {
    use v5.36;
    use Moo;
    with 'PointService::Role';

    has inner => (
        is       => 'ro',
        does     => 'PointService::Role',
        required => 1,
    );

    sub add_points ($self, $user, $amount) {
        return $self->inner->add_points($user, $amount);
    }
}
1;
