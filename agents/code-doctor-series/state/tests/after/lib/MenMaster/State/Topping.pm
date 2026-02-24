package MenMaster::State::Topping;
use v5.36;
use parent 'MenMaster::State';

sub serve($self) {
    my $ctx = $self->context;
    $ctx->transition_to('MenMaster::State::Completed');
    return "提供完了: $ctx->{order_name}（お待たせしました！）";
}

1;
