# UnderwaterTempleTheme.pm - 水中神殿テーマ
package UnderwaterTempleTheme;
use v5.36;
use Moo;

extends 'DungeonTheme';

sub wall_char ($self)  { '≈' }
sub floor_char ($self) { '~' }

1;
