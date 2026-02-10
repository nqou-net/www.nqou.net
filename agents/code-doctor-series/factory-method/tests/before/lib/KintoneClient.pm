package KintoneClient;
use v5.36;
use Moo;

has token        => (is => 'ro', required => 1);
has app_id       => (is => 'ro', required => 1);
has _synced_data => (is => 'rw', default  => sub { [] });

sub upsert($self, $data) {

    # 実際はHTTPリクエストを送信するが、デモでは内部に保存
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
