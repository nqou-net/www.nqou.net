# ExpiryChecker.pm
# Perl v5.36+, Moo

package ExpiryChecker;
use v5.36;
use Moo;
extends 'PaymentChecker';

sub check ($self, $request) {
    my $expiry_year  = $request->{expiry_year}  // 0;
    my $expiry_month = $request->{expiry_month} // 0;

    my ($current_year, $current_month) = (localtime)[5,4];
    $current_year  += 1900;
    $current_month += 1;

    my $is_expired = $expiry_year < $current_year ||
        ($expiry_year == $current_year && $expiry_month < $current_month);

    if ($is_expired) {
        return {
            ok     => 0,
            reason => 'カードの有効期限が切れています',
        };
    }

    return $self->pass_to_next($request);
}

1;
