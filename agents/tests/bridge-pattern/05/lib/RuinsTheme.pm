# RuinsTheme.pm - 遺跡テーマ
package RuinsTheme;
use v5.36;
use Moo;

extends 'DungeonTheme';

sub wall_char ($self)  { '▓' }
sub floor_char ($self) { '▒' }

1;
