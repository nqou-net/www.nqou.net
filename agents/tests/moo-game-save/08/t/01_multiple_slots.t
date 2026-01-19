use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Episode 08: Multiple save slot management
# Focus on managing multiple save slots and slot selection

# Test managing multiple independent save slots
subtest 'manage multiple independent save slots' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Slot 0: Start of game
    $player->hp(100);
    $player->gold(0);
    $player->position('町');
    my $slot0 = $manager->save_game($player);
    is $slot0, 0, 'slot 0 created';
    
    # Slot 1: After forest
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    my $slot1 = $manager->save_game($player);
    is $slot1, 1, 'slot 1 created';
    
    # Slot 2: Before boss
    $player->hp(60);
    $player->gold(100);
    $player->position('洞窟入口');
    my $slot2 = $manager->save_game($player);
    is $slot2, 2, 'slot 2 created';
    
    # Verify all slots are independent
    is $manager->saves->[0]->hp, 100, 'slot 0 hp preserved';
    is $manager->saves->[0]->position, '町', 'slot 0 position preserved';
    
    is $manager->saves->[1]->hp, 70, 'slot 1 hp preserved';
    is $manager->saves->[1]->position, '森', 'slot 1 position preserved';
    
    is $manager->saves->[2]->hp, 60, 'slot 2 hp preserved';
    is $manager->saves->[2]->position, '洞窟入口', 'slot 2 position preserved';
};

# Test loading from specific slots
subtest 'load from specific save slot' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create 3 different saves
    $player->hp(100);
    my $slot0 = $manager->save_game($player);
    
    $player->hp(70);
    my $slot1 = $manager->save_game($player);
    
    $player->hp(40);
    my $slot2 = $manager->save_game($player);
    
    # Current state
    $player->hp(0);
    
    # Load from slot 1
    $manager->load_game($player, $slot1);
    is $player->hp, 70, 'loaded from slot 1';
    
    # Load from slot 0
    $manager->load_game($player, $slot0);
    is $player->hp, 100, 'loaded from slot 0';
    
    # Load from slot 2
    $manager->load_game($player, $slot2);
    is $player->hp, 40, 'loaded from slot 2';
};

# Test slot information display
subtest 'list_saves shows all slots' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create multiple saves
    $player->hp(100);
    $player->gold(0);
    $player->position('町');
    $manager->save_game($player);
    
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $manager->save_game($player);
    
    # Capture output
    my $output;
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die;
        $manager->list_saves;
        close STDOUT;
    }
    
    like $output, qr/セーブデータ一覧/, 'shows header';
    like $output, qr/スロット 0/, 'shows slot 0';
    like $output, qr/スロット 1/, 'shows slot 1';
    like $output, qr/HP: 100/, 'shows slot 0 hp';
    like $output, qr/HP: 70/, 'shows slot 1 hp';
    like $output, qr/位置: 町/, 'shows slot 0 position';
    like $output, qr/位置: 森/, 'shows slot 1 position';
};

# Test overwriting slots (implicit via continuous saves)
subtest 'continuous saves create new slots' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Save 5 times
    for my $i (1..5) {
        $player->hp(100 - $i * 10);
        my $slot = $manager->save_game($player);
        is $slot, $i - 1, "save $i creates slot ${\($i-1)}";
    }
    
    is scalar $manager->saves->@*, 5, 'has 5 saves';
    
    # Each save is preserved
    is $manager->saves->[0]->hp, 90, 'save 1 preserved';
    is $manager->saves->[1]->hp, 80, 'save 2 preserved';
    is $manager->saves->[2]->hp, 70, 'save 3 preserved';
    is $manager->saves->[3]->hp, 60, 'save 4 preserved';
    is $manager->saves->[4]->hp, 50, 'save 5 preserved';
};

# Test use case: manual save + auto save slots
subtest 'mix of manual and auto saves' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Manual save
    $player->hp(100);
    $player->position('manual_save_point');
    my $manual_slot = $manager->save_game($player);
    
    # Auto saves
    $player->hp(70);
    $player->position('auto_checkpoint_1');
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint 1');
        close STDOUT;
    }
    
    $player->hp(40);
    $player->position('auto_checkpoint_2');
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint 2');
        close STDOUT;
    }
    
    # All saves are independent
    is scalar $manager->saves->@*, 3, 'has 3 saves';
    is $manager->saves->[0]->hp, 100, 'manual save preserved';
    is $manager->saves->[1]->hp, 70, 'auto save 1 preserved';
    is $manager->saves->[2]->hp, 40, 'auto save 2 preserved';
};

# Test recovery scenario: choose which save to load
subtest 'choose save slot for recovery' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create save points
    $player->hp(100);
    $player->gold(0);
    my $early_save = $manager->save_game($player);
    
    $player->hp(70);
    $player->gold(50);
    my $mid_save = $manager->save_game($player);
    
    $player->hp(50);
    $player->gold(100);
    my $late_save = $manager->save_game($player);
    
    # Die
    $player->hp(0);
    $player->gold(1000);  # shouldn't matter
    
    # Decide to load from mid save
    $manager->load_game($player, $mid_save);
    
    is $player->hp, 70, 'restored to mid save hp';
    is $player->gold, 50, 'restored to mid save gold';
    
    # Change mind, load from early save
    $manager->load_game($player, $early_save);
    
    is $player->hp, 100, 'restored to early save hp';
    is $player->gold, 0, 'restored to early save gold';
};

# Test slot validation
subtest 'has_save validates slot existence' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    ok !$manager->has_save(0), 'slot 0 empty initially';
    ok !$manager->has_save(5), 'slot 5 empty initially';
    
    $manager->save_game($player);
    ok $manager->has_save(0), 'slot 0 exists after save';
    ok !$manager->has_save(1), 'slot 1 still empty';
    ok !$manager->has_save(99), 'slot 99 still empty';
};

done_testing;
