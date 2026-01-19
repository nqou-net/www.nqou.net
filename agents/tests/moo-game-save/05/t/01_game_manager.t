use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Test GameManager creation
subtest 'GameManager creation' => sub {
    my $manager = GameManager->new;
    ok $manager, 'GameManager created';
    is_deeply $manager->saves, [], 'starts with empty saves';
};

# Test save_game
subtest 'save_game stores player state' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    
    my $slot = $manager->save_game($player);
    is $slot, 0, 'first save returns slot 0';
    
    is scalar $manager->saves->@*, 1, 'saves array has 1 element';
    
    my $saved = $manager->saves->[0];
    is $saved->hp, 70, 'saved hp is 70';
    is $saved->gold, 50, 'saved gold is 50';
    is $saved->position, '森', 'saved position is 森';
};

# Test multiple saves
subtest 'multiple saves in different slots' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Save 1
    $player->hp(100);
    $player->gold(0);
    my $slot1 = $manager->save_game($player);
    is $slot1, 0, 'first slot is 0';
    
    # Save 2
    $player->hp(70);
    $player->gold(50);
    my $slot2 = $manager->save_game($player);
    is $slot2, 1, 'second slot is 1';
    
    # Save 3
    $player->hp(40);
    $player->gold(100);
    my $slot3 = $manager->save_game($player);
    is $slot3, 2, 'third slot is 2';
    
    is scalar $manager->saves->@*, 3, 'has 3 saves';
    
    is $manager->saves->[0]->hp, 100, 'slot 0 hp is 100';
    is $manager->saves->[1]->hp, 70, 'slot 1 hp is 70';
    is $manager->saves->[2]->hp, 40, 'slot 2 hp is 40';
};

# Test has_save
subtest 'has_save checks slot existence' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    ok !$manager->has_save(0), 'slot 0 does not exist initially';
    
    $manager->save_game($player);
    ok $manager->has_save(0), 'slot 0 exists after save';
    ok !$manager->has_save(1), 'slot 1 does not exist';
    
    $manager->save_game($player);
    ok $manager->has_save(1), 'slot 1 exists after second save';
};

# Test load_game
subtest 'load_game restores player state' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Save state
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $player->add_item('薬草');
    my $slot = $manager->save_game($player);
    
    # Change player
    $player->hp(0);
    $player->gold(0);
    $player->position('nowhere');
    $player->items([]);
    
    # Load from slot
    $manager->load_game($player, $slot);
    
    is $player->hp, 70, 'hp restored';
    is $player->gold, 50, 'gold restored';
    is $player->position, '森', 'position restored';
    is_deeply $player->items, ['薬草'], 'items restored';
};

# Test load_game from different slots
subtest 'load_game from different slots' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Save multiple states
    $player->hp(100);
    my $slot0 = $manager->save_game($player);
    
    $player->hp(70);
    my $slot1 = $manager->save_game($player);
    
    $player->hp(40);
    my $slot2 = $manager->save_game($player);
    
    # Die
    $player->hp(0);
    
    # Load from slot 2
    $manager->load_game($player, $slot2);
    is $player->hp, 40, 'loaded from slot 2';
    
    # Load from slot 0
    $manager->load_game($player, $slot0);
    is $player->hp, 100, 'loaded from slot 0';
    
    # Load from slot 1
    $manager->load_game($player, $slot1);
    is $player->hp, 70, 'loaded from slot 1';
};

# Test load_game with invalid slot
subtest 'load_game dies with invalid slot' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    eval { $manager->load_game($player, 0); };
    like $@, qr/セーブデータがありません/, 'dies with no save data';
    
    $manager->save_game($player);
    
    eval { $manager->load_game($player, 99); };
    like $@, qr/セーブデータがありません/, 'dies with invalid slot number';
};

# Test save independence
subtest 'saves are independent of player changes' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->add_item('薬草');
    my $slot = $manager->save_game($player);
    
    # Change player items
    $player->add_item('毒薬');
    
    # Saved data should be unchanged
    is_deeply $manager->saves->[$slot]->items, ['薬草'],
        'saved items unchanged after player modification';
};

# Test game over scenario with manager
subtest 'game over with save manager' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Progress and save
    $player->move_to('森');
    $player->take_damage(30);
    $player->earn_gold(50);
    my $checkpoint = $manager->save_game($player);
    
    ok $player->is_alive, 'alive at checkpoint';
    
    # Continue and die
    $player->move_to('洞窟');
    $player->take_damage(100);
    ok !$player->is_alive, 'dead after battle';
    
    # Reload
    $manager->load_game($player, $checkpoint);
    ok $player->is_alive, 'alive after reload';
    is $player->position, '森', 'back at checkpoint';
};

# Test encapsulation - manager hides snapshot details
subtest 'manager encapsulation' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->hp(70);
    $player->gold(50);
    
    # Simple save
    my $slot = $manager->save_game($player);
    
    # Simple load
    $player->hp(0);
    $manager->load_game($player, $slot);
    
    is $player->hp, 70, 'restored without knowing snapshot internals';
};

done_testing;
