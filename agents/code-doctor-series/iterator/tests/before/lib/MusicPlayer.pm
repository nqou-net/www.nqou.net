package MusicPlayer;
use v5.36;

sub new($class) {
    bless { log => [] }, $class;
}

sub play_all($self, $songs) {
    # 悪い点: 配列リファレンスであることを前提としている
    # 悪い点: インデックスアクセスによる密結合
    for (my $i = 0; $i < $songs->@*; $i++) {
        my $song = $songs->[$i];
        
        # 処理: 再生ログに記録（実際の再生の代わり）
        push $self->{log}->@*, "Playing: " . $song->{title};
    }
}

sub get_log($self) {
    return $self->{log};
}

1;
