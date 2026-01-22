#!/usr/bin/env perl
# bridge_demo.pl - Bridgeパターンによるダンジョン生成
use v5.36;
use lib 'lib';

use CastleTheme;
use MazeAlgorithm;

# 城テーマ × 迷路型アルゴリズム
my $dungeon = CastleTheme->new(
    algorithm => MazeAlgorithm->new,
    width     => 41,
    height    => 11,
);

$dungeon->generate;
print $dungeon->render;
