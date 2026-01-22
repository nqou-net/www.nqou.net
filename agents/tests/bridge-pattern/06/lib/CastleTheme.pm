# CastleTheme.pm - 城テーマ
package CastleTheme;
use v5.36;
use Moo;

extends 'DungeonTheme';

sub wall_char ($self)  { '█' }
sub floor_char ($self) { '░' }

1;
