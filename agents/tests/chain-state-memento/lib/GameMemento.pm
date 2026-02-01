package GameMemento;
use v5.36;
use warnings;
use Moo;
use Storable qw(dclone);

# Memento パターン: ゲーム状態のスナップショット

has state     => (is => 'ro', required => 1);
has label     => (is => 'ro', default  => 'セーブポイント');
has timestamp => (is => 'ro', default  => sub { time() });

sub BUILDARGS($class, %args) {

    # 状態のディープコピーを作成
    if (exists $args{state}) {
        $args{state} = dclone($args{state});
    }
    return \%args;
}

sub get_state($self) {

    # 状態のディープコピーを返す
    return dclone($self->state);
}

sub describe($self) {
    my $loc = $self->state->{location} // '不明';
    my $hp  = $self->state->{hp}       // '?';
    return sprintf('%s (場所: %s, HP: %s)', $self->label, $loc, $hp);
}

1;
