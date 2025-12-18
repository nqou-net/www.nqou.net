package JsonRpc::RequestFactory;
use v5.38;
use Moo;
use JsonRpc::Request;
use JsonRpc::Notification;
use JsonRpc::Version;
use JsonRpc::MethodName;
use namespace::clean;

sub from_hash {
    my ($class, $hashref) = @_;

    my $jsonrpc = JsonRpc::Version->new(value => $hashref->{jsonrpc});
    my $method  = JsonRpc::MethodName->new(value => $hashref->{method});
    my $params  = $hashref->{params};

    if (exists $hashref->{id}) {

        # Request
        return JsonRpc::Request->new(
            jsonrpc => $jsonrpc,
            method  => $method,
            params  => $params,
            id      => $hashref->{id},
        );
    }
    else {
        # Notification
        return JsonRpc::Notification->new(
            jsonrpc => $jsonrpc,
            method  => $method,
            params  => $params,
        );
    }
}

1;
