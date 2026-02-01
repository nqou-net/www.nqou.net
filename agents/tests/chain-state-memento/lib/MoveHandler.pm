package MoveHandler;
use v5.36;
use warnings;
use Moo;

with 'CommandHandler';

# 移動コマンドを処理するハンドラ

my %MAP = (
    '森の入り口' => {'北' => '小道'},
    '小道'    => {'北' => '泉', '東' => '古い小屋', '南' => '森の入り口'},
    '古い小屋'  => {'西' => '小道'},
    '泉'     => {'南' => '小道', '北' => '宝物庫'},
    '宝物庫'   => {'南' => '泉'},
);

my %DIRECTIONS = map { $_ => 1 } qw(北 南 東 西);

sub can_handle($self, $context, $command) {
    return exists $DIRECTIONS{$command};
}

sub handle($self, $context, $command) {
    my $current = $context->{location};
    my $next    = $MAP{$current}{$command};

    if ($next) {
        $context->{location} = $next;
        return {
            handled => 1,
            message => "${command}へ進んだ。",
        };
    }

    return {
        handled => 1,
        message => 'そちらには進めない。',
    };
}

1;
