# LimitChecker.pm
# Perl v5.36+, Moo

package LimitChecker;
use v5.36;
use Moo;
extends 'PaymentChecker';

has 'limit' => (
    is      => 'ro',
    default => 100_000,  # デフォルト10万円
);

sub check ($self, $request) {
    my $amount = $request->{amount} // 0;

    if ($amount >= $self->limit) {
        return {
            ok     => 0,
            reason => sprintf('金額が上限（%d円）を超えています', $self->limit),
        };
    }

    # OKなら次のチェッカーへ
    return $self->pass_to_next($request);
}

1;
