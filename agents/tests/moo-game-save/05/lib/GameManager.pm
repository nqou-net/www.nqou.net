package GameManager;
# Perl v5.36 以降
# 外部依存: Moo

use v5.36;
use Moo;

has saves => (
    is      => 'ro',
    default => sub { [] },
);

sub save_game ($self, $player) {
    my $snapshot = $player->save_snapshot;
    push $self->saves->@*, $snapshot;
    return scalar $self->saves->@* - 1;  # スロット番号を返す
}

sub load_game ($self, $player, $slot_number) {
    unless ($self->has_save($slot_number)) {
        die "セーブデータがありません: スロット $slot_number\n";
    }
    
    my $snapshot = $self->saves->[$slot_number];
    $player->restore_from_snapshot($snapshot);
}

sub has_save ($self, $slot_number) {
    return defined $self->saves->[$slot_number];
}

sub list_saves ($self) {
    my @saves = $self->saves->@*;
    
    if (@saves == 0) {
        say "セーブデータがありません";
        return;
    }
    
    say "=== セーブデータ一覧 ===";
    for my $i (0 .. $#saves) {
        my $save = $saves[$i];
        say "スロット $i:";
        say "  HP: " . $save->hp;
        say "  所持金: " . $save->gold . "G";
        say "  位置: " . $save->position;
    }
    say "";
}

1;
