package DetailedFormatter;

# 第5回: Bridgeで出力とスタイルを分離
# DetailedFormatter.pm - 詳細スタイルの実装

use v5.36;
use warnings;
use Moo;

with 'FormatterRole';

sub format_name($self) {'Detailed'}

sub format_title($self, $whisky) {
    return $whisky->{name};
}

sub format_basic($self, $whisky) {
    return "産地: $whisky->{region} / 熟成: $whisky->{age}年 / 度数: $whisky->{abv}%";
}

sub format_notes($self, $whisky) {
    return "香り: $whisky->{nose}\n味わい: $whisky->{palate}\n余韻: $whisky->{finish}";
}

sub format_rating($self, $whisky) {
    return "評価: $whisky->{rating}/100";
}

1;
