package MenMaster::State::Completed;
use v5.36;
use parent 'MenMaster::State';

sub take_order($self, $order_name, $noodle_type = 'regular') {
    my $ctx = $self->context;
    $ctx->{order_name}  = $order_name;
    $ctx->{noodle_type} = $noodle_type;
    $ctx->transition_to('MenMaster::State::Preparing');
    return "注文OK: $order_name ($noodle_type)";
}

1;
