package SyncClient::Slack;
use v5.36;
use Moo;
with 'Role::SyncClient';

has webhook_url    => (is => 'ro', required => 1);
has _sent_messages => (is => 'rw', default  => sub { [] });

sub sync($self, $data) {
    my $message = ref $data eq 'HASH' ? ($data->{message} // 'データ同期完了') : $data;
    push $self->_sent_messages->@*,
        {
        type    => 'slack',
        message => $message,
        status  => 'posted',
        };
    return 1;
}

sub get_sent_messages($self) {
    return $self->_sent_messages;
}

1;
