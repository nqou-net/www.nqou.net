use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Episode 09: Complete playable RPG integration
# Test that all components work together in a realistic game scenario

# Test complete game flow with all features
subtest 'complete game playthrough with save/load' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # === Act 1: Tutorial ===
    is $player->hp, 100, 'start with 100 HP';
    is $player->position, '町', 'start in town';
    
    # Move to forest
    $player->move_to('森');
    
    # Fight slime
    $player->take_damage(30);
    $player->earn_gold(50);
    $player->add_item('薬草');
    
    # Manual save after forest
    my $forest_save = $manager->save_game($player);
    is $player->hp, 70, 'HP 70 after forest';
    is $player->gold, 50, 'earned 50 gold';
    
    # === Act 2: Dungeon ===
    $player->move_to('洞窟');
    
    # Auto-save before boss
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'ボス戦前');
        close STDOUT;
    }
    my $boss_save = scalar $manager->saves->@* - 1;
    
    # Boss fight - player dies
    $player->take_damage(100);
    ok !$player->is_alive, 'died to boss';
    
    # === Reload from boss save ===
    $manager->load_game($player, $boss_save);
    ok $player->is_alive, 'alive after reload';
    is $player->hp, 70, 'HP restored';
    is $player->position, '洞窟', 'at dungeon';
    
    # === Act 3: Retry and win ===
    # Use healing item (simulate)
    $player->remove_item('薬草');
    $player->hp($player->hp + 30);
    
    # Win boss fight
    $player->take_damage(50);
    $player->earn_gold(100);
    ok $player->is_alive, 'survived boss';
    
    # Final save
    my $victory_save = $manager->save_game($player);
    
    # Verify we have multiple saves
    is scalar $manager->saves->@*, 3, 'have 3 saves (forest, boss, victory)';
    
    # Can load any previous point
    $manager->load_game($player, $forest_save);
    is $player->position, '森', 'can return to forest';
};

# Test auto-save integration
subtest 'auto-save prevents progress loss' => sub {
    my $manager = GameManager->new(auto_save => 1);
    my $player = Player->new;
    
    # Progress without manual saving
    $player->move_to('森');
    $player->take_damage(30);
    
    # Auto-save triggered
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint');
        close STDOUT;
    }
    
    # Continue and die
    $player->take_damage(100);
    ok !$player->is_alive, 'player died';
    
    # Auto-save preserved progress
    ok $manager->has_save(0), 'auto-save exists';
    $manager->load_game($player, 0);
    is $player->hp, 70, 'restored from auto-save';
};

# Test multiple character scenario (different players)
subtest 'multiple characters using same manager' => sub {
    my $manager = GameManager->new;
    
    # Character 1
    my $char1 = Player->new;
    $char1->hp(80);
    $char1->position('char1_location');
    my $char1_slot = $manager->save_game($char1);
    
    # Character 2
    my $char2 = Player->new;
    $char2->hp(60);
    $char2->position('char2_location');
    my $char2_slot = $manager->save_game($char2);
    
    # Load char1 data into char2
    $manager->load_game($char2, $char1_slot);
    is $char2->hp, 80, 'char2 loaded char1 data';
    is $char2->position, 'char1_location', 'char2 at char1 location';
    
    # Load char2 original data back
    $manager->load_game($char2, $char2_slot);
    is $char2->hp, 60, 'char2 back to original';
};

# Test branching storyline with saves
subtest 'branching storyline with multiple endings' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Common start
    $player->move_to('分岐点');
    $player->hp(100);
    my $branch_point = $manager->save_game($player);
    
    # Path A: 悪の道
    $player->move_to('悪の城');
    $player->gold(1000);
    my $evil_ending = $manager->save_game($player);
    
    # Return to branch point for Path B
    $manager->load_game($player, $branch_point);
    is $player->position, '分岐点', 'back at branch point';
    
    # Path B: 善の道
    $player->move_to('光の神殿');
    $player->gold(100);
    my $good_ending = $manager->save_game($player);
    
    # Can access both endings
    is $manager->saves->[$evil_ending]->position, '悪の城', 'evil ending preserved';
    is $manager->saves->[$good_ending]->position, '光の神殿', 'good ending preserved';
};

# Test realistic error handling
subtest 'handle invalid load attempts gracefully' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Try to load non-existent save
    eval {
        $manager->load_game($player, 99);
    };
    like $@, qr/セーブデータがありません/, 'error for non-existent slot';
    
    # Create one save
    $manager->save_game($player);
    
    # Can load valid save
    eval {
        $manager->load_game($player, 0);
    };
    is $@, '', 'no error for valid slot';
    
    # Still error for invalid slot
    eval {
        $manager->load_game($player, 5);
    };
    like $@, qr/セーブデータがありません/, 'still error for slot 5';
};

# Test data persistence across game sessions (simulated)
subtest 'save data remains consistent' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create complex state
    $player->hp(42);
    $player->gold(777);
    $player->position('secret_room');
    $player->add_item('legendary_sword');
    $player->add_item('magic_shield');
    $player->add_item('phoenix_down');
    
    # Save
    my $slot = $manager->save_game($player);
    
    # Simulate "quitting game" - destroy player
    $player = undef;
    
    # Simulate "new game session" - create new player
    $player = Player->new;
    
    # Load saved data
    $manager->load_game($player, $slot);
    
    # All data restored perfectly
    is $player->hp, 42, 'hp restored in new session';
    is $player->gold, 777, 'gold restored in new session';
    is $player->position, 'secret_room', 'position restored in new session';
    is_deeply $player->items, ['legendary_sword', 'magic_shield', 'phoenix_down'],
        'items restored in new session';
};

done_testing;
