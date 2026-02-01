package SimpleFormatter;

# 第5回: Bridgeで出力とスタイルを分離
# SimpleFormatter.pm - シンプルスタイルの実装

use v5.36;
use warnings;
use Moo;

with 'FormatterRole';

sub format_name($self) {'Simple'}

sub format_title($self, $whisky) {
    return $whisky->{name};
}

sub format_basic($self, $whisky) {
    return "$whisky->{region} $whisky->{rating}点";
}

sub format_notes($self, $whisky) {
    return '';    # シンプルスタイルではテイスティングノートは表示しない
}

sub format_rating($self, $whisky) {
    return '';    # 基本情報に含まれているため省略
}

1;
