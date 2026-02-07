use v5.36;
use Test2::V0;
use lib 'lib';
use MusicPlayer;
use PlaylistIterator;

subtest 'Iterator Playback' => sub {
    my $player = MusicPlayer->new;
    my $songs  = [{title => 'Song A'}, {title => 'Song B'}, {title => 'Song C'},];

    # 配列をIteratorでラップして渡す
    my $iterator = PlaylistIterator->new($songs);
    $player->play_all($iterator);

    is $player->get_log, ['Playing: Song A', 'Playing: Song B', 'Playing: Song C',], 'All songs played via Iterator';
};

done_testing;
