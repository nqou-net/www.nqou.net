package MusicPlayer;
use v5.36;

sub new($class) {
    bless {log => []}, $class;
}

sub play_all($self, $iterator) {

    # 改善点: 具体的なデータ構造（配列など）に依存しない
    # Iteratorインターフェース（プロトコル）に従うものなら何でも受け入れる
    while ($iterator->has_next) {
        my $song = $iterator->next;
        push $self->{log}->@*, "Playing: " . $song->{title};
    }
}

sub get_log($self) {
    return $self->{log};
}

1;
