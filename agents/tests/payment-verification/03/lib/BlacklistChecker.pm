# BlacklistChecker.pm
# Perl v5.36+, Moo

package BlacklistChecker;
use v5.36;
use Moo;
extends 'PaymentChecker';

has 'blacklist' => (
    is      => 'ro',
    default => sub { [] },
);

sub check ($self, $request) {
    my $card_number = $request->{card_number} // '';

    for my $blacklisted (@{ $self->blacklist }) {
        if ($card_number eq $blacklisted) {
            return {
                ok     => 0,
                reason => 'このカードは使用できません',
            };
        }
    }

    return $self->pass_to_next($request);
}

1;
