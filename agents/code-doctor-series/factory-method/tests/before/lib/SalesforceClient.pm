package SalesforceClient;
use v5.36;
use Moo;

has api_key      => (is => 'ro', required => 1);
has endpoint     => (is => 'ro', required => 1);
has _synced_data => (is => 'rw', default  => sub { [] });

sub push_records($self, $data) {

    # 実際はHTTPリクエストを送信するが、デモでは内部に保存
    push $self->_synced_data->@*,
        {
        type   => 'salesforce',
        data   => $data,
        status => 'pushed',
        };
    return 1;
}

sub get_synced_data($self) {
    return $self->_synced_data;
}

1;
