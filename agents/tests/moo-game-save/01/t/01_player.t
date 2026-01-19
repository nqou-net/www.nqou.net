#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;

subtest 'Player creation with defaults' => sub {
    my $player = Player->new;
    is $player->hp, 100, 'default HP is 100';
    is $player->gold, 0, 'default gold is 0';
    is $player->position, '町', 'default position is 町';
    ok $player->is_alive, 'player is alive initially';
};

subtest 'take_damage method' => sub {
    my $player = Player->new;
    $player->take_damage(30);
    is $player->hp, 70, 'HP reduced by 30';
    ok $player->is_alive, 'player still alive at 70 HP';
    
    $player->take_damage(80);
    is $player->hp, 0, 'HP cannot go below 0';
    ok !$player->is_alive, 'player is dead at 0 HP';
};

subtest 'earn_gold method' => sub {
    my $player = Player->new;
    $player->earn_gold(50);
    is $player->gold, 50, 'gold increased by 50';
    $player->earn_gold(100);
    is $player->gold, 150, 'gold accumulated to 150';
};

subtest 'move_to method' => sub {
    my $player = Player->new;
    $player->move_to('森');
    is $player->position, '森', 'moved to 森';
    $player->move_to('洞窟');
    is $player->position, '洞窟', 'moved to 洞窟';
};

subtest 'game scenario' => sub {
    my $player = Player->new;
    
    # 森へ移動
    $player->move_to('森');
    is $player->position, '森', 'moved to forest';
    
    # スライムと戦闘
    $player->take_damage(30);
    is $player->hp, 70, 'damaged by slime';
    ok $player->is_alive, 'survived slime attack';
    
    # 勝利
    $player->earn_gold(50);
    is $player->gold, 50, 'earned gold from slime';
    
    # 洞窟へ移動
    $player->move_to('洞窟');
    is $player->position, '洞窟', 'moved to cave';
    
    # ドラゴンと戦闘
    $player->take_damage(80);
    is $player->hp, 0, 'killed by dragon';
    ok !$player->is_alive, 'game over';
};

done_testing;
