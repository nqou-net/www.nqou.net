package SaveManager;
use v5.36;
use warnings;
use Moo;
use GameMemento;

# Caretaker: セーブデータを管理

has saves     => (is => 'rw', default => sub { [] });
has max_saves => (is => 'ro', default => 10);

sub save($self, $context, $label = 'セーブポイント') {
    my $memento = GameMemento->new(
        state => $context,
        label => $label,
    );

    my @saves = @{$self->saves};
    push @saves, $memento;

    # 最大保存数を超えたら古いものを削除
    shift @saves if @saves > $self->max_saves;

    $self->saves(\@saves);

    return '状態をセーブしました: ' . $memento->describe;
}

sub load($self, $index) {
    my @saves = @{$self->saves};

    if ($index < 0 || $index >= @saves) {
        return (undef, 'そのセーブデータは存在しません。');
    }

    my $memento = $saves[$index];
    return ($memento->get_state, 'ロードしました: ' . $memento->describe);
}

sub load_latest($self) {
    my @saves = @{$self->saves};
    return (undef, 'セーブデータがありません。') unless @saves;
    return $self->load($#saves);
}

sub list_saves($self) {
    my @saves = @{$self->saves};
    return 'セーブデータがありません。' unless @saves;

    my @lines = ('セーブデータ一覧:');
    for my $i (0 .. $#saves) {
        push @lines, sprintf('  [%d] %s', $i, $saves[$i]->describe);
    }
    return join("\n", @lines);
}

sub clear($self) {
    $self->saves([]);
    return 'セーブデータをクリアしました。';
}

1;
