use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;

# Test basic attributes and defaults
subtest 'Player creation and defaults' => sub {
    my $player = Player->new;
    is $player->hp, 100, 'default HP is 100';
    is $player->gold, 0, 'default gold is 0';
    is $player->position, '町', 'default position is 町';
    is_deeply $player->items, [], 'default items is empty arrayref';
};

# Test damage mechanics
subtest 'take_damage method' => sub {
    my $player = Player->new;
    
    $player->take_damage(30);
    is $player->hp, 70, 'HP reduced by 30';
    
    $player->take_damage(50);
    is $player->hp, 20, 'HP reduced by another 50';
    
    $player->take_damage(100);
    is $player->hp, 0, 'HP cannot go below 0';
};

# Test gold mechanics
subtest 'earn_gold method' => sub {
    my $player = Player->new;
    
    $player->earn_gold(50);
    is $player->gold, 50, 'earned 50 gold';
    
    $player->earn_gold(30);
    is $player->gold, 80, 'earned another 30 gold';
};

# Test movement
subtest 'move_to method' => sub {
    my $player = Player->new;
    
    $player->move_to('森');
    is $player->position, '森', 'moved to 森';
    
    $player->move_to('洞窟');
    is $player->position, '洞窟', 'moved to 洞窟';
};

# Test is_alive
subtest 'is_alive method' => sub {
    my $player = Player->new;
    
    ok $player->is_alive, 'player is alive with 100 HP';
    
    $player->take_damage(50);
    ok $player->is_alive, 'player is alive with 50 HP';
    
    $player->take_damage(50);
    ok !$player->is_alive, 'player is not alive with 0 HP';
};

# Test item management
subtest 'item management' => sub {
    my $player = Player->new;
    
    is_deeply $player->items, [], 'starts with no items';
    
    $player->add_item('薬草');
    is_deeply $player->items, ['薬草'], 'added 薬草';
    
    $player->add_item('毒薬');
    is_deeply $player->items, ['薬草', '毒薬'], 'added 毒薬';
};

# Test simple variable save/restore (works with primitive values)
subtest 'simple save/restore with primitive values' => sub {
    my $player = Player->new;
    
    # Initial state
    $player->move_to('森');
    $player->take_damage(30);
    $player->earn_gold(50);
    
    # Save state
    my $saved_hp = $player->hp;
    my $saved_gold = $player->gold;
    my $saved_position = $player->position;
    
    # Change state
    $player->move_to('洞窟');
    $player->take_damage(70);
    $player->earn_gold(100);
    
    is $player->hp, 0, 'HP is 0 after damage';
    is $player->gold, 150, 'gold is 150';
    is $player->position, '洞窟', 'position is 洞窟';
    
    # Restore state
    $player->hp($saved_hp);
    $player->gold($saved_gold);
    $player->position($saved_position);
    
    is $player->hp, 70, 'HP restored to 70';
    is $player->gold, 50, 'gold restored to 50';
    is $player->position, '森', 'position restored to 森';
};

# Test reference copy trap (shallow copy problem)
subtest 'reference copy trap - shallow copy problem' => sub {
    my $player = Player->new;
    
    # Add initial item
    $player->add_item('薬草');
    is_deeply $player->items, ['薬草'], 'has 薬草';
    
    # Save state (shallow copy - this is the trap!)
    my $saved_hp = $player->hp;
    my $saved_items = $player->items;  # Reference copy!
    
    # Add another item after save
    $player->add_item('毒薬');
    is_deeply $player->items, ['薬草', '毒薬'], 'now has 薬草 and 毒薬';
    
    # Restore state
    $player->hp($saved_hp);
    $player->items($saved_items);
    
    # The trap: saved_items still points to the same array!
    is_deeply $player->items, ['薬草', '毒薬'], 
        'BUG: 毒薬 is still there! This is the reference copy trap';
    
    # What we expected:
    # is_deeply $player->items, ['薬草'], 'expected only 薬草';
};

# Test that deep copy would work (for comparison)
subtest 'deep copy solution - creating new arrayref' => sub {
    my $player = Player->new;
    
    # Add initial item
    $player->add_item('薬草');
    is_deeply $player->items, ['薬草'], 'has 薬草';
    
    # Save state (deep copy - create new arrayref)
    my $saved_hp = $player->hp;
    my $saved_items = [ @{$player->items} ];  # Deep copy!
    
    # Add another item after save
    $player->add_item('毒薬');
    is_deeply $player->items, ['薬草', '毒薬'], 'now has 薬草 and 毒薬';
    
    # Restore state
    $player->hp($saved_hp);
    $player->items($saved_items);
    
    # With deep copy, restore works correctly
    is_deeply $player->items, ['薬草'], 
        'SUCCESS: only 薬草 remains after restore with deep copy';
};

done_testing;
