use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;

# Test restore_from_snapshot basic functionality
subtest 'restore_from_snapshot basic functionality' => sub {
    my $player = Player->new;
    
    # Set initial state
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $player->add_item('薬草');
    
    # Save snapshot
    my $snapshot = $player->save_snapshot;
    
    # Change player state
    $player->hp(0);
    $player->gold(150);
    $player->position('洞窟');
    $player->add_item('毒消し草');
    
    # Verify changed state
    is $player->hp, 0, 'player hp changed to 0';
    is $player->gold, 150, 'player gold changed to 150';
    is $player->position, '洞窟', 'player position changed';
    is_deeply $player->items, ['薬草', '毒消し草'], 'player items changed';
    
    # Restore from snapshot
    $player->restore_from_snapshot($snapshot);
    
    # Verify restored state
    is $player->hp, 70, 'hp restored to 70';
    is $player->gold, 50, 'gold restored to 50';
    is $player->position, '森', 'position restored to 森';
    is_deeply $player->items, ['薬草'], 'items restored to [薬草]';
};

# Test save and restore cycle preserves data
subtest 'save and restore cycle preserves data' => sub {
    my $player = Player->new;
    
    $player->hp(85);
    $player->gold(120);
    $player->position('山');
    $player->add_item('剣');
    $player->add_item('盾');
    
    my $snapshot = $player->save_snapshot;
    
    # Dramatically change state
    $player->hp(1);
    $player->gold(0);
    $player->position('墓地');
    $player->items([]);
    
    # Restore
    $player->restore_from_snapshot($snapshot);
    
    is $player->hp, 85, 'hp preserved through cycle';
    is $player->gold, 120, 'gold preserved through cycle';
    is $player->position, '山', 'position preserved through cycle';
    is_deeply $player->items, ['剣', '盾'], 'items preserved through cycle';
};

# Test items array independence after restore
subtest 'items array independence after restore' => sub {
    my $player = Player->new;
    $player->add_item('薬草');
    
    my $snapshot = $player->save_snapshot;
    
    # Change player items
    $player->add_item('毒薬');
    
    # Restore
    $player->restore_from_snapshot($snapshot);
    
    # Player should only have 薬草
    is_deeply $player->items, ['薬草'], 'player has only 薬草 after restore';
    
    # Now modify player items
    $player->add_item('エリクサー');
    
    # Snapshot should still be unchanged
    is_deeply $snapshot->items, ['薬草'], 
        'snapshot unchanged after modifying restored player';
};

# Test game over scenario
subtest 'game over and restore scenario' => sub {
    my $player = Player->new;
    
    # Progress through game
    $player->move_to('森');
    $player->take_damage(30);
    $player->earn_gold(50);
    $player->add_item('薬草');
    
    # Save at checkpoint
    my $checkpoint = $player->save_snapshot;
    
    ok $player->is_alive, 'player alive at checkpoint';
    is $player->hp, 70, 'checkpoint hp is 70';
    
    # Continue to dangerous area
    $player->move_to('洞窟');
    $player->add_item('毒消し草');
    $player->take_damage(80);
    
    # Game over
    ok !$player->is_alive, 'player dead after dragon fight';
    is $player->hp, 0, 'hp is 0';
    
    # Restore from checkpoint
    $player->restore_from_snapshot($checkpoint);
    
    ok $player->is_alive, 'player alive after restore';
    is $player->hp, 70, 'hp restored to 70';
    is $player->position, '森', 'back at checkpoint location';
    is_deeply $player->items, ['薬草'], 'checkpoint items restored';
};

# Test multiple save/restore cycles
subtest 'multiple save/restore cycles' => sub {
    my $player = Player->new;
    
    # Save 1
    $player->hp(100);
    my $save1 = $player->save_snapshot;
    
    # Save 2
    $player->hp(70);
    my $save2 = $player->save_snapshot;
    
    # Save 3
    $player->hp(40);
    my $save3 = $player->save_snapshot;
    
    # Die
    $player->hp(0);
    
    # Restore to save3
    $player->restore_from_snapshot($save3);
    is $player->hp, 40, 'restored to save3';
    
    # Restore to save2
    $player->restore_from_snapshot($save2);
    is $player->hp, 70, 'restored to save2';
    
    # Restore to save1
    $player->restore_from_snapshot($save1);
    is $player->hp, 100, 'restored to save1';
    
    # Saves are still valid
    is $save1->hp, 100, 'save1 unchanged';
    is $save2->hp, 70, 'save2 unchanged';
    is $save3->hp, 40, 'save3 unchanged';
};

# Test encapsulation - restore doesn't expose internals
subtest 'restore encapsulation' => sub {
    my $player = Player->new;
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    $player->add_item('薬草');
    
    my $snapshot = $player->save_snapshot;
    
    # Change everything
    $player->hp(0);
    $player->gold(0);
    $player->position('nowhere');
    $player->items([]);
    
    # Simple restore call - no knowledge of internals needed
    $player->restore_from_snapshot($snapshot);
    
    # Everything restored
    is $player->hp, 70, 'hp restored';
    is $player->gold, 50, 'gold restored';
    is $player->position, '森', 'position restored';
    is_deeply $player->items, ['薬草'], 'items restored';
};

# Test symmetry of save and restore
subtest 'save and restore symmetry' => sub {
    my $player1 = Player->new;
    $player1->hp(55);
    $player1->gold(77);
    $player1->position('temple');
    $player1->add_item('holy water');
    
    # Save from player1
    my $snapshot = $player1->save_snapshot;
    
    # Create new player and restore
    my $player2 = Player->new;
    $player2->restore_from_snapshot($snapshot);
    
    # player2 should have same state as player1 had
    is $player2->hp, 55, 'hp matches';
    is $player2->gold, 77, 'gold matches';
    is $player2->position, 'temple', 'position matches';
    is_deeply $player2->items, ['holy water'], 'items match';
};

done_testing;
