use v5.36;
use Test2::V0;
use lib 'lib';
use MusicPlayer;

subtest 'Standard Array Playback' => sub {
    my $player = MusicPlayer->new;
    my $songs  = [{title => 'Song A'}, {title => 'Song B'}, {title => 'Song C'},];

    $player->play_all($songs);

    is $player->get_log, ['Playing: Song A', 'Playing: Song B', 'Playing: Song C',], 'All songs played from array reference';
};

done_testing;
