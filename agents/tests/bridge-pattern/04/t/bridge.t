#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';

use GenerationAlgorithm;
use RandomAlgorithm;
use MazeAlgorithm;
use DungeonTheme;
use CaveTheme;
use CastleTheme;
use RuinsTheme;

# Test 1: Roleの確認
ok( RandomAlgorithm->DOES('GenerationAlgorithm'), 'RandomAlgorithm does GenerationAlgorithm' );
ok( MazeAlgorithm->DOES('GenerationAlgorithm'), 'MazeAlgorithm does GenerationAlgorithm' );

# Test 2: CaveTheme + RandomAlgorithm
my $cave_random = CaveTheme->new(
    algorithm => RandomAlgorithm->new,
    width     => 21,
    height    => 11,
);
ok( defined $cave_random, 'CaveTheme with RandomAlgorithm created' );
$cave_random->generate;
my $output = $cave_random->render;
like( $output, qr/[#.]/, 'CaveTheme render contains # and .' );

# Test 3: CastleTheme + MazeAlgorithm
my $castle_maze = CastleTheme->new(
    algorithm => MazeAlgorithm->new,
    width     => 21,
    height    => 11,
);
ok( defined $castle_maze, 'CastleTheme with MazeAlgorithm created' );
$castle_maze->generate;
my $castle_output = $castle_maze->render;
like( $castle_output, qr/[█░]/, 'CastleTheme render contains castle chars' );

# Test 4: RuinsTheme + RandomAlgorithm
my $ruins_random = RuinsTheme->new(
    algorithm => RandomAlgorithm->new,
    width     => 21,
    height    => 11,
);
$ruins_random->generate;
my $ruins_output = $ruins_random->render;
like( $ruins_output, qr/[▓▒]/, 'RuinsTheme render contains ruins chars' );

# Test 5: テーマとアルゴリズムの自由な組み合わせ
my @theme_classes = qw(CaveTheme CastleTheme RuinsTheme);
my @algo_classes  = qw(RandomAlgorithm MazeAlgorithm);

for my $theme_class (@theme_classes) {
    for my $algo_class (@algo_classes) {
        my $algo    = $algo_class->new;
        my $dungeon = $theme_class->new(
            algorithm => $algo,
            width     => 21,
            height    => 11,
        );
        $dungeon->generate;
        my $output = $dungeon->render;
        ok( length($output) > 0, "$theme_class + $algo_class works" );
    }
}

done_testing();
