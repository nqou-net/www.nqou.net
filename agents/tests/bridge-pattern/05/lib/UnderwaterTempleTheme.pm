# UnderwaterTempleTheme.pm - 水中神殿テーマ
package UnderwaterTempleTheme;
use v5.36;
use Moo;

extends 'DungeonTheme';

sub wall_char ($self)  { '≈' }    # 海藻に覆われた壁
sub floor_char ($self) { '~' }    # 水底

1;
