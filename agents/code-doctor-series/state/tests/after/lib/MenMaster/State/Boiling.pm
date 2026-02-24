package MenMaster::State::Boiling;
use v5.36;
use parent 'MenMaster::State';

sub start_topping($self) {
    my $ctx = $self->context;
    $ctx->transition_to('MenMaster::State::Topping');
    return "盛り付け開始: $ctx->{order_name}";
}

1;
