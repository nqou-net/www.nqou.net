#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use MazeDungeon;

my $dungeon = MazeDungeon->new(
    width  => 41,
    height => 11,
);

$dungeon->generate;
print $dungeon->render;
