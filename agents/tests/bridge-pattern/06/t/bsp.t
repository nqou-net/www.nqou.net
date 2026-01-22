#!/usr/bin/env perl
use v5.36;
use Test::More;
use lib 'lib';

use BSPAlgorithm;
use CastleTheme;
use UnderwaterTempleTheme;

# Test 1: BSPAlgorithmのRole確認
ok( BSPAlgorithm->DOES('GenerationAlgorithm'), 'BSPAlgorithm does GenerationAlgorithm' );

# Test 2: CastleTheme + BSPAlgorithm
my $castle_bsp = CastleTheme->new(
    algorithm => BSPAlgorithm->new,
    width     => 41,
    height    => 15,
);
$castle_bsp->generate;
my $output = $castle_bsp->render;
like( $output, qr/[█░]/, 'CastleTheme + BSPAlgorithm works' );

# Test 3: UnderwaterTempleTheme + BSPAlgorithm
my $underwater_bsp = UnderwaterTempleTheme->new(
    algorithm => BSPAlgorithm->new,
    width     => 41,
    height    => 15,
);
$underwater_bsp->generate;
my $underwater_output = $underwater_bsp->render;
like( $underwater_output, qr/[≈~]/, 'UnderwaterTempleTheme + BSPAlgorithm works' );

# Test 4: 部屋が生成されている（床が存在する）
like( $output, qr/░/, 'BSP creates rooms with floors' );

done_testing();
