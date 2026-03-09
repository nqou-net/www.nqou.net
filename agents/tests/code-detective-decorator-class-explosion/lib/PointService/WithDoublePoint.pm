package PointService::WithDoublePoint {
    use v5.36;
    use Moo;
    extends 'PointService::Decorator';

    sub add_points ($self, $user, $amount) {
        my $doubled = $amount * 2;
        print "[CAMPAIGN] Points doubled: $amount -> $doubled\n";
        $self->inner->add_points($user, $doubled);
    }
}
1;
