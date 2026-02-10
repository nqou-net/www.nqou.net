package SlackClient;
use v5.36;
use Moo;

has webhook_url    => (is => 'ro', required => 1);
has _sent_messages => (is => 'rw', default  => sub { [] });

sub post_message($self, $message) {

    # 実際はWebhookにPOSTするが、デモでは内部に保存
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
