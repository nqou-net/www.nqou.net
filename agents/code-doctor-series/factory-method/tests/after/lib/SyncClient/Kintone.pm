package SyncClient::Kintone;
use v5.36;
use Moo;
with 'Role::SyncClient';

has token        => (is => 'ro', required => 1);
has app_id       => (is => 'ro', required => 1);
has _synced_data => (is => 'rw', default  => sub { [] });

sub sync($self, $data) {
    push $self->_synced_data->@*,
        {
        type   => 'kintone',
        data   => $data,
        status => 'upserted',
        };
    return 1;
}

sub get_synced_data($self) {
    return $self->_synced_data;
}

1;
