package PlayerSnapshot;
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use Moo;

has hp => (
    is       => 'ro',
    required => 1,
);

has gold => (
    is       => 'ro',
    required => 1,
);

has position => (
    is       => 'ro',
    required => 1,
);

has items => (
    is       => 'ro',
    required => 1,
);

1;
