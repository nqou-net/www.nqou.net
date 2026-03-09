package PointService::WithNotification {
    use v5.36;
    use Moo;
    extends 'PointService::Decorator';

    sub add_points ($self, $user, $amount) {
        $self->inner->add_points($user, $amount);
        print "[MAIL] Sent notification to " . $user->email . "\n";
    }
}
1;
