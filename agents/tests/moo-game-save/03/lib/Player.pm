package Player;
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use Moo;
use PlayerSnapshot;

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
    default => sub { [] },
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

sub remove_item ($self, $item) {
    my @new = grep { $_ ne $item } $self->items->@*;
    $self->items(\@new);
}

sub show_status ($self) {
    say "HP: " . $self->hp;
    say "所持金: " . $self->gold . "G";
    say "位置: " . $self->position;
    my $items = $self->items;
    my $items_str = ($items->@*) ? join(', ', $items->@*) : 'なし';
    say "所持品: " . $items_str;
    say "";
}

sub save_snapshot ($self) {
    return PlayerSnapshot->new(
        hp       => $self->hp,
        gold     => $self->gold,
        position => $self->position,
        items    => [$self->items->@*],  # 配列の中身を展開して新しい配列リファレンスを作成（コピー）
    );
}

1;
