package MenMaster;
use v5.36;

# 麺マスター — State パターン適用版
# リファクタリング: コードドクター

use MenMaster::State::WaitingOrder;
use MenMaster::State::Preparing;
use MenMaster::State::Boiling;
use MenMaster::State::Topping;
use MenMaster::State::Completed;

sub new($class) {
    my $self = bless {
        order_name  => '',
        noodle_type => 'regular',
        state       => undef,
    }, $class;
    $self->transition_to('MenMaster::State::WaitingOrder');
    return $self;
}

sub transition_to($self, $state_class) {
    $self->{state} = $state_class->new(context => $self);
}

sub take_order($self, $order_name, $noodle_type = 'regular') {
    $self->{state}->take_order($order_name, $noodle_type);
}

sub start_boiling($self) {
    $self->{state}->start_boiling;
}

sub start_topping($self) {
    $self->{state}->start_topping;
}

sub serve($self) {
    $self->{state}->serve;
}

sub status($self) {
    return $self->{state}->name;
}

sub reset($self) {
    $self->{order_name}  = '';
    $self->{noodle_type} = 'regular';
    $self->transition_to('MenMaster::State::WaitingOrder');
    return "リセット完了（まっさらだ！）";
}

1;
