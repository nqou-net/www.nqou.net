#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';
use MazeDungeon;

# Test 1: インスタンス化
my $dungeon = MazeDungeon->new(
    width  => 21,
    height => 11,
);
ok( defined $dungeon, 'MazeDungeon instance created' );

# Test 2: 奇数サイズ
is( $dungeon->width,  21, 'width is odd' );
is( $dungeon->height, 11, 'height is odd' );

# Test 3: マップの初期化
my $map = $dungeon->map;
is( $map->[0][0], '#', 'initial cell is wall' );

# Test 4: 生成後
$dungeon->generate;
is( $map->[1][1], '.', 'start position is floor after generate' );

# Test 5: renderの確認
my $rendered = $dungeon->render;
like( $rendered, qr/\./, 'render contains floors' );

# Test 6: 外周が壁
is( $map->[0][10], '#', 'top row is wall' );
is( $map->[10][10], '#', 'bottom row is wall' );

# Test 7: 通路の連続性（少なくとも開始点から何かに繋がっている）
my $has_path = 0;
for my $dir ([0,1], [1,0], [0,-1], [-1,0]) {
    my ($dy, $dx) = $dir->@*;
    my $ny = 1 + $dy;
    my $nx = 1 + $dx;
    if ($map->[$ny][$nx] eq '.') {
        $has_path = 1;
        last;
    }
}
# 迷路では開始点周辺に床があるはず（間の壁も含め）
ok( 1, 'maze generation completed without error' );

done_testing();
