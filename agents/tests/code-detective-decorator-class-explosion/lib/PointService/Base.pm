package PointService::Base {
    use v5.36;
    use Moo;
    with 'PointService::Role';

    sub add_points ($self, $user, $amount) {
        # output is captured in tests
        print "[SYSTEM] $amount points added to " . $user->name . "\n";
    }
}
1;
