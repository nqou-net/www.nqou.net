#!/usr/bin/env perl
# dungeon_demo.pl - ダンジョン生成デモ
use v5.36;
use lib 'lib';
use Dungeon;

# ダンジョンを生成
my $dungeon = Dungeon->new(
    width  => 40,
    height => 10,
);

$dungeon->generate;

# 表示
print $dungeon->render;
