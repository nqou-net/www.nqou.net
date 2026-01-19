use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Episode 07: セーブデータを守ろう（カプセル化）
# This episode focuses on verifying that save data is protected and immutable

# Test PlayerSnapshot immutability (review from episode 03)
subtest 'PlayerSnapshot is immutable' => sub {
    my $snapshot = PlayerSnapshot->new(
        hp       => 70,
        gold     => 50,
        position => '森',
        items    => ['薬草'],
    );
    
    # Try to modify each attribute - should fail
    eval { $snapshot->hp(100); };
    ok $@, 'cannot modify hp';
    
    eval { $snapshot->gold(999); };
    ok $@, 'cannot modify gold';
    
    eval { $snapshot->position('hack'); };
    ok $@, 'cannot modify position';
    
    eval { $snapshot->items(['hack']); };
    ok $@, 'cannot modify items';
    
    # Verify values unchanged
    is $snapshot->hp, 70, 'hp unchanged';
    is $snapshot->gold, 50, 'gold unchanged';
    is $snapshot->position, '森', 'position unchanged';
    is_deeply $snapshot->items, ['薬草'], 'items unchanged';
};

# Test that saves in GameManager are protected
subtest 'saves array is read-only reference but contents are mutable' => sub {
    my $manager = GameManager->new;
    
    # saves attribute itself is read-only
    eval { $manager->saves(['hack']); };
    ok $@, 'cannot replace saves array reference';
    
    # But we can push to the array (this is expected behavior)
    my $player = Player->new;
    $player->hp(70);
    my $slot = $manager->save_game($player);
    
    is scalar $manager->saves->@*, 1, 'can add saves via save_game';
};

# Test that snapshot independence is maintained
subtest 'snapshots remain independent after save' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->add_item('薬草');
    my $slot = $manager->save_game($player);
    
    # Modify player after save
    $player->add_item('毒薬');
    $player->add_item('エリクサー');
    
    # Saved snapshot should be unchanged
    is_deeply $manager->saves->[$slot]->items, ['薬草'],
        'saved snapshot items unchanged';
    is_deeply $player->items, ['薬草', '毒薬', 'エリクサー'],
        'player has new items';
};

# Test encapsulation: save/load hides internal details
subtest 'encapsulation via save/load methods' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Setup complex state
    $player->hp(55);
    $player->gold(77);
    $player->position('temple');
    $player->add_item('sword');
    $player->add_item('shield');
    
    # Save without knowing internal structure
    my $slot = $manager->save_game($player);
    
    # Destroy state
    $player->hp(0);
    $player->gold(0);
    $player->position('void');
    $player->items([]);
    
    # Restore without knowing internal structure
    $manager->load_game($player, $slot);
    
    # Everything restored correctly
    is $player->hp, 55, 'hp restored';
    is $player->gold, 77, 'gold restored';
    is $player->position, 'temple', 'position restored';
    is_deeply $player->items, ['sword', 'shield'], 'items restored';
};

# Test that attempting to modify saved data directly fails
subtest 'cannot modify saved snapshots directly' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->hp(70);
    $player->gold(50);
    my $slot = $manager->save_game($player);
    
    my $snapshot = $manager->saves->[$slot];
    
    # Try to cheat by modifying the snapshot
    eval { $snapshot->hp(999); };
    ok $@, 'cannot cheat by modifying saved hp';
    
    eval { $snapshot->gold(9999); };
    ok $@, 'cannot cheat by modifying saved gold';
    
    # Snapshot values should be unchanged
    is $snapshot->hp, 70, 'saved hp still 70';
    is $snapshot->gold, 50, 'saved gold still 50';
};

# Test data integrity through save/load cycle
subtest 'data integrity maintained through save/load' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create specific state
    $player->hp(42);
    $player->gold(123);
    $player->position('secret_area');
    $player->add_item('rare_item');
    
    # Save
    my $slot = $manager->save_game($player);
    
    # Load multiple times
    for my $i (1..5) {
        $player->hp(999);  # corrupt
        $manager->load_game($player, $slot);
        
        # Always restores correctly
        is $player->hp, 42, "hp correct after load $i";
        is $player->gold, 123, "gold correct after load $i";
        is $player->position, 'secret_area', "position correct after load $i";
        is_deeply $player->items, ['rare_item'], "items correct after load $i";
    }
};

done_testing;
