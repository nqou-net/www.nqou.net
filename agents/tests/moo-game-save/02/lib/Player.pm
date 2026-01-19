package Player;
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use Moo;

has hp => (
    is      => 'rw',
    default => 100,
);

has gold => (
    is      => 'rw',
    default => 0,
);

has position => (
    is      => 'rw',
    default => '町',
);

has items => (
    is      => 'rw',
    default => sub { [] },  # 配列リファレンス
);

sub take_damage ($self, $amount) {
    $self->hp($self->hp - $amount);
    if ($self->hp < 0) {
        $self->hp(0);
    }
}

sub earn_gold ($self, $amount) {
    $self->gold($self->gold + $amount);
}

sub move_to ($self, $location) {
    $self->position($location);
}

sub is_alive ($self) {
    return $self->hp > 0;
}

sub add_item ($self, $item) {
    push $self->items->@*, $item;
}

sub show_status ($self) {
    say "HP: " . $self->hp;
    say "所持金: " . $self->gold . "G";
    say "位置: " . $self->position;
    say "";
}

sub show_items ($self) {
    say "所持アイテム: " . join(', ', $self->items->@*);
}

1;
