package MethodName;
use Moo;
has value => (
    is  => 'ro',
    isa => sub { die "method name cannot be empty" if $_[0] eq '' },
);

1;
__END__
