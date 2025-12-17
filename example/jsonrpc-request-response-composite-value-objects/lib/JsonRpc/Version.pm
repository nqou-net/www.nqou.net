package JsonRpc::Version;
use v5.38;
use Moo;

has value => (
    is       => 'ro',
    required => 1,
    default  => '2.0',
    isa      => sub {
        my $val = shift;

        $val eq '2.0'
            or die "JSON-RPC version must be '2.0', got '$val'";
    },
);

1;
