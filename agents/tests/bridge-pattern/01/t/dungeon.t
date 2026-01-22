#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';
use Dungeon;

# Test 1: ダンジョンのインスタンス化
my $dungeon = Dungeon->new(
    width  => 20,
    height => 10,
);
ok( defined $dungeon, 'Dungeon instance created' );

# Test 2: 属性の確認
is( $dungeon->width,  20, 'width is correct' );
is( $dungeon->height, 10, 'height is correct' );

# Test 3: マップの初期化（すべて壁）
my $map = $dungeon->map;
is( scalar $map->@*, 10, 'map has correct number of rows' );
is( scalar $map->[0]->@*, 20, 'first row has correct number of columns' );
is( $map->[0][0], '#', 'initial cell is wall' );

# Test 4: 生成後のマップ
$dungeon->generate;
my $rendered = $dungeon->render;
like( $rendered, qr/[#.]/, 'render contains walls or floors' );

# Test 5: 外周が壁のまま
is( $map->[0][5], '#', 'top row is still wall' );
is( $map->[9][5], '#', 'bottom row is still wall' );
is( $map->[5][0], '#', 'left column is still wall' );
is( $map->[5][19], '#', 'right column is still wall' );

# Test 6: renderの出力行数
my @lines = split /\n/, $rendered;
is( scalar @lines, 10, 'render has correct number of lines' );

done_testing();
