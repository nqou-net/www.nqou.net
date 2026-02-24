package MenMaster::State::Preparing;
use v5.36;
use parent 'MenMaster::State';

sub start_boiling($self) {
    my $ctx = $self->context;
    $ctx->transition_to('MenMaster::State::Boiling');
    return "茹で開始: $ctx->{order_name}";
}

1;
