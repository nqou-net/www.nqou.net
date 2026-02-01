package ProFormatter;

# 第5回: Bridgeで出力とスタイルを分離
# ProFormatter.pm - プロフェッショナルスタイルの実装

use v5.36;
use warnings;
use utf8;
use Moo;

with 'FormatterRole';

sub format_name($self) {'Pro'}

sub format_title($self, $whisky) {
    return $whisky->{name};
}

sub format_basic($self, $whisky) {
    return join(' / ', "産地: $whisky->{region}", "熟成: $whisky->{age}年", "度数: $whisky->{abv}%",);
}

sub format_notes($self, $whisky) {
    my @notes;
    push @notes, "【香り】$whisky->{nose}";
    push @notes, "【味わい】$whisky->{palate}";
    push @notes, "【余韻】$whisky->{finish}";
    return join("\n", @notes);
}

sub format_rating($self, $whisky) {
    my $rating = $whisky->{rating};
    my $stars  = '★' x int($rating / 20) . '☆' x (5 - int($rating / 20));
    return "$stars $rating/100";
}

1;
