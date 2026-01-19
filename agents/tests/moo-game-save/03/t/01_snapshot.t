use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;

# Test PlayerSnapshot creation and read-only attributes
subtest 'PlayerSnapshot creation and ro attributes' => sub {
    my $snapshot = PlayerSnapshot->new(
        hp       => 70,
        gold     => 50,
        position => '森',
        items    => ['薬草'],
    );
    
    is $snapshot->hp, 70, 'snapshot hp is 70';
    is $snapshot->gold, 50, 'snapshot gold is 50';
    is $snapshot->position, '森', 'snapshot position is 森';
    is_deeply $snapshot->items, ['薬草'], 'snapshot items is [薬草]';
    
    # Try to modify snapshot (should fail)
    eval { $snapshot->hp(100); };
    like $@, qr/read-only|read only|cannot set|usage/i, 
        'cannot modify hp (is => ro)';
};

# Test PlayerSnapshot requires all attributes
subtest 'PlayerSnapshot requires all attributes' => sub {
    eval {
        PlayerSnapshot->new(
            hp   => 70,
            gold => 50,
            # missing position and items
        );
    };
    like $@, qr/required|Missing required/i, 
        'dies without required attributes';
};

# Test Player save_snapshot method
subtest 'Player save_snapshot creates independent snapshot' => sub {
    my $player = Player->new;
    
    # Set initial state
    $player->move_to('森');
    $player->take_damage(30);
    $player->earn_gold(50);
    $player->add_item('薬草');
    
    # Save snapshot
    my $snapshot = $player->save_snapshot;
    
    # Verify snapshot captured state
    is $snapshot->hp, 70, 'snapshot captured hp 70';
    is $snapshot->gold, 50, 'snapshot captured gold 50';
    is $snapshot->position, '森', 'snapshot captured position 森';
    is_deeply $snapshot->items, ['薬草'], 'snapshot captured items [薬草]';
    
    # Modify player after snapshot
    $player->move_to('洞窟');
    $player->take_damage(70);
    $player->earn_gold(100);
    $player->add_item('毒消し草');
    
    # Verify player changed
    is $player->hp, 0, 'player hp changed to 0';
    is $player->gold, 150, 'player gold changed to 150';
    is $player->position, '洞窟', 'player position changed to 洞窟';
    is_deeply $player->items, ['薬草', '毒消し草'], 
        'player items changed';
    
    # Verify snapshot unchanged (deep copy)
    is $snapshot->hp, 70, 'snapshot hp still 70';
    is $snapshot->gold, 50, 'snapshot gold still 50';
    is $snapshot->position, '森', 'snapshot position still 森';
    is_deeply $snapshot->items, ['薬草'], 
        'snapshot items still [薬草] - deep copy works!';
};

# Test snapshot independence with items array
subtest 'snapshot items array is independent (deep copy)' => sub {
    my $player = Player->new;
    $player->add_item('薬草');
    
    my $snapshot = $player->save_snapshot;
    
    # Add item to player
    $player->add_item('毒薬');
    
    # Snapshot should not be affected
    is_deeply $snapshot->items, ['薬草'], 
        'snapshot items unchanged after player modification';
    is_deeply $player->items, ['薬草', '毒薬'], 
        'player has both items';
};

# Test snapshot immutability protects against modification
subtest 'snapshot immutability' => sub {
    my $player = Player->new;
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $player->add_item('薬草');
    
    my $snapshot = $player->save_snapshot;
    
    # Try to modify each attribute
    eval { $snapshot->hp(100); };
    ok $@, 'cannot modify snapshot hp';
    
    eval { $snapshot->gold(999); };
    ok $@, 'cannot modify snapshot gold';
    
    eval { $snapshot->position('town'); };
    ok $@, 'cannot modify snapshot position';
    
    eval { $snapshot->items(['different']); };
    ok $@, 'cannot modify snapshot items';
    
    # Verify snapshot unchanged
    is $snapshot->hp, 70, 'hp unchanged';
    is $snapshot->gold, 50, 'gold unchanged';
    is $snapshot->position, '森', 'position unchanged';
    is_deeply $snapshot->items, ['薬草'], 'items unchanged';
};

# Test encapsulation - save_snapshot hides Player internals
subtest 'encapsulation - save_snapshot hides internals' => sub {
    my $player = Player->new;
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $player->add_item('薬草');
    
    # We don't need to know Player's internal structure
    # Just call save_snapshot
    my $snapshot = $player->save_snapshot;
    
    # The snapshot has all the data we need
    ok $snapshot, 'snapshot created';
    is $snapshot->hp, 70, 'has hp';
    is $snapshot->gold, 50, 'has gold';
    is $snapshot->position, '森', 'has position';
    is_deeply $snapshot->items, ['薬草'], 'has items';
};

# Test multiple snapshots are independent
subtest 'multiple snapshots are independent' => sub {
    my $player = Player->new;
    
    # First snapshot
    $player->hp(100);
    $player->gold(0);
    my $snapshot1 = $player->save_snapshot;
    
    # Change state
    $player->hp(70);
    $player->gold(50);
    my $snapshot2 = $player->save_snapshot;
    
    # Change state again
    $player->hp(0);
    $player->gold(150);
    my $snapshot3 = $player->save_snapshot;
    
    # Each snapshot is independent
    is $snapshot1->hp, 100, 'snapshot1 hp is 100';
    is $snapshot1->gold, 0, 'snapshot1 gold is 0';
    
    is $snapshot2->hp, 70, 'snapshot2 hp is 70';
    is $snapshot2->gold, 50, 'snapshot2 gold is 50';
    
    is $snapshot3->hp, 0, 'snapshot3 hp is 0';
    is $snapshot3->gold, 150, 'snapshot3 gold is 150';
};

done_testing;
