package SyncClient::Salesforce;
use v5.36;
use Moo;
with 'Role::SyncClient';

has api_key      => (is => 'ro', required => 1);
has endpoint     => (is => 'ro', required => 1);
has _synced_data => (is => 'rw', default  => sub { [] });

sub sync($self, $data) {
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
