#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';

use UnderwaterTempleTheme;
use MazeAlgorithm;

# Test 1: 水中神殿テーマのインスタンス化
my $dungeon = UnderwaterTempleTheme->new(
    algorithm => MazeAlgorithm->new,
    width     => 21,
    height    => 11,
);
ok( defined $dungeon, 'UnderwaterTempleTheme created' );

# Test 2: 生成とレンダリング
$dungeon->generate;
my $output = $dungeon->render;
like( $output, qr/[≈~]/, 'UnderwaterTempleTheme render contains underwater chars' );

# Test 3: 既存コードを変更せずに動作
ok( UnderwaterTempleTheme->isa('DungeonTheme'), 'UnderwaterTempleTheme extends DungeonTheme' );

done_testing();
