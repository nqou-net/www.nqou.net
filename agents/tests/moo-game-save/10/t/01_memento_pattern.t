use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Episode 10: Memento Pattern - Design Pattern Explanation
# This episode is theoretical, so tests verify the pattern structure

# Test Memento Pattern: Three roles
# 1. Originator (Player) - creates and restores from memento
# 2. Memento (PlayerSnapshot) - stores state immutably  
# 3. Caretaker (GameManager) - manages mementos without knowing internals

subtest 'Originator role: Player creates and restores mementos' => sub {
    my $player = Player->new;
    
    # Setup state
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    
    # Originator creates memento
    my $memento = $player->save_snapshot;
    isa_ok $memento, 'PlayerSnapshot', 'creates PlayerSnapshot memento';
    
    # Change originator state
    $player->hp(0);
    $player->gold(0);
    
    # Originator restores from memento
    $player->restore_from_snapshot($memento);
    is $player->hp, 70, 'originator restored state';
    
    # Originator knows how to save/restore itself
    ok $player->can('save_snapshot'), 'originator has save_snapshot';
    ok $player->can('restore_from_snapshot'), 'originator has restore_from_snapshot';
};

subtest 'Memento role: PlayerSnapshot stores state immutably' => sub {
    my $memento = PlayerSnapshot->new(
        hp       => 70,
        gold     => 50,
        position => '森',
        items    => ['薬草'],
    );
    
    # Memento provides read access
    is $memento->hp, 70, 'memento provides read access';
    ok $memento->can('hp'), 'memento has accessor methods';
    
    # Memento is immutable (read-only)
    eval { $memento->hp(100); };
    ok $@, 'memento is immutable';
    
    # Memento doesn't expose how to modify internals
    ok !$memento->can('set_hp'), 'memento has no setter methods';
};

subtest 'Caretaker role: GameManager manages mementos' => sub {
    my $caretaker = GameManager->new;
    my $originator = Player->new;
    
    # Caretaker stores mementos without knowing internals
    $originator->hp(100);
    my $slot1 = $caretaker->save_game($originator);
    
    $originator->hp(70);
    my $slot2 = $caretaker->save_game($originator);
    
    # Caretaker manages multiple mementos
    is scalar $caretaker->saves->@*, 2, 'caretaker stores multiple mementos';
    
    # Caretaker doesn't modify mementos
    ok !$caretaker->can('modify_snapshot'), 'caretaker cannot modify mementos';
    
    # Caretaker provides mementos back to originator
    $caretaker->load_game($originator, $slot1);
    is $originator->hp, 100, 'caretaker provided memento for restoration';
};

# Test key properties of Memento Pattern

subtest 'Encapsulation: memento hides originator internals' => sub {
    my $player = Player->new;
    $player->hp(70);
    $player->gold(50);
    $player->position('森');
    
    my $snapshot = $player->save_snapshot;
    
    # Snapshot doesn't expose how Player stores data internally
    # External code only sees the snapshot's interface
    ok $snapshot->can('hp'), 'can read hp';
    ok $snapshot->can('gold'), 'can read gold';
    ok $snapshot->can('position'), 'can read position';
    
    # But cannot modify or access private details
    eval { $snapshot->hp(999); };
    ok $@, 'cannot modify snapshot';
};

subtest 'Separation of concerns: each role has clear responsibility' => sub {
    # Originator: knows how to save/restore its own state
    my $player = Player->new;
    ok $player->can('save_snapshot'), 'Originator: creates memento';
    ok $player->can('restore_from_snapshot'), 'Originator: restores from memento';
    
    # Memento: passively stores state
    my $snapshot = PlayerSnapshot->new(
        hp => 70, gold => 50, position => '森', items => []
    );
    ok $snapshot->can('hp'), 'Memento: provides read access';
    
    # Caretaker: manages memento collection
    my $manager = GameManager->new;
    ok $manager->can('save_game'), 'Caretaker: saves mementos';
    ok $manager->can('load_game'), 'Caretaker: retrieves mementos';
    ok $manager->can('has_save'), 'Caretaker: tracks mementos';
};

subtest 'Memento pattern supports undo/history' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Create history
    $player->hp(100);
    $manager->save_game($player);  # History point 1
    
    $player->hp(70);
    $manager->save_game($player);  # History point 2
    
    $player->hp(40);
    $manager->save_game($player);  # History point 3
    
    # Can undo to any point in history
    $manager->load_game($player, 1);
    is $player->hp, 70, 'undo to history point 2';
    
    $manager->load_game($player, 0);
    is $player->hp, 100, 'undo to history point 1';
    
    $manager->load_game($player, 2);
    is $player->hp, 40, 'redo to history point 3';
};

# Test benefits of Memento Pattern

subtest 'Benefit: externalize state without breaking encapsulation' => sub {
    my $player = Player->new;
    $player->hp(70);
    
    # State is externalized (can be stored/passed around)
    my $snapshot = $player->save_snapshot;
    
    # But encapsulation is maintained (snapshot is read-only)
    eval { $snapshot->hp(999); };
    ok $@, 'encapsulation preserved - cannot cheat';
    
    # Original player can change freely
    $player->hp(50);
    is $player->hp, 50, 'player can change';
    is $snapshot->hp, 70, 'snapshot unchanged';
};

subtest 'Benefit: simplifies originator by delegating storage' => sub {
    my $player = Player->new;
    
    # Player doesn't need to manage save history
    ok !$player->can('list_saves'), 'player does not manage history';
    ok !$player->can('save_to_slot'), 'player does not manage slots';
    
    # That responsibility belongs to Caretaker
    my $manager = GameManager->new;
    ok $manager->can('save_game'), 'manager handles storage';
    ok $manager->can('list_saves'), 'manager handles history';
};

# Test Memento vs other patterns

subtest 'Memento vs Command pattern' => sub {
    # Memento: captures state at a point in time
    my $player = Player->new;
    $player->hp(70);
    my $memento = $player->save_snapshot;
    
    # Memento stores state, not operations
    ok !$memento->can('execute'), 'memento does not have execute';
    ok !$memento->can('undo'), 'memento does not have undo';
    
    # Memento is passive data
    ok $memento->can('hp'), 'memento provides data access';
    
    # To restore, Originator uses the memento
    $player->hp(0);
    $player->restore_from_snapshot($memento);
    is $player->hp, 70, 'originator interprets memento';
};

done_testing;
