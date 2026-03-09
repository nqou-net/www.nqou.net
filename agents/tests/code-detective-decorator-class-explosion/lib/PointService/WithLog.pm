package PointService::WithLog {
    use v5.36;
    use Moo;
    extends 'PointService::Decorator';

    sub add_points ($self, $user, $amount) {
        print "[LOG] Start adding points...\n";
        $self->inner->add_points($user, $amount);
        print "[LOG] End adding points.\n";
    }
}
1;
