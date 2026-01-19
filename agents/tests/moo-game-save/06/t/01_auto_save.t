use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Player;
use PlayerSnapshot;
use GameManager;

# Test auto_save attribute
subtest 'auto_save attribute defaults to enabled' => sub {
    my $manager = GameManager->new;
    ok $manager->auto_save, 'auto_save defaults to 1 (enabled)';
};

# Test auto_save can be toggled
subtest 'auto_save can be toggled' => sub {
    my $manager = GameManager->new;
    
    $manager->auto_save(0);
    ok !$manager->auto_save, 'auto_save can be disabled';
    
    $manager->auto_save(1);
    ok $manager->auto_save, 'auto_save can be enabled';
};

# Test try_auto_save with auto_save enabled
subtest 'try_auto_save when enabled' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->hp(70);
    $player->gold(50);
    
    # Capture output
    my $slot;
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $slot = $manager->try_auto_save($player, 'test reason');
        close STDOUT;
        like $output, qr/オートセーブ: test reason/, 'prints auto-save message with reason';
        like $output, qr/スロット/, 'prints slot number';
    }
    
    is scalar $manager->saves->@*, 1, 'saved one snapshot';
    is $manager->saves->[0]->hp, 70, 'saved correct hp';
};

# Test try_auto_save with auto_save disabled
subtest 'try_auto_save when disabled' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $manager->auto_save(0);
    
    $player->hp(70);
    
    # Capture output
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'test reason');
        close STDOUT;
        ok !defined($output) || $output eq '', 'prints nothing when disabled';
    }
    
    is scalar $manager->saves->@*, 0, 'did not save';
};

# Test try_auto_save without reason
subtest 'try_auto_save without reason parameter' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Capture output
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player);
        close STDOUT;
        like $output, qr/オートセーブしました/, 'prints generic message without reason';
    }
    
    is scalar $manager->saves->@*, 1, 'saved one snapshot';
};

# Test auto_save scenario: boss area
subtest 'auto_save before boss fight' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Progress through game
    $player->move_to('森');
    $player->hp(70);
    $player->gold(50);
    
    # Auto-save before boss
    my $saves_before = scalar $manager->saves->@*;
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'ボス戦前');
        close STDOUT;
    }
    
    is scalar $manager->saves->@*, $saves_before + 1, 'auto-saved before boss';
    is $manager->saves->[-1]->hp, 70, 'saved current HP';
    is $manager->saves->[-1]->position, '森', 'saved current position';
};

# Test auto_save scenario: area transition
subtest 'auto_save on area transition' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    $player->move_to('町');
    $player->hp(100);
    
    # Auto-save on transition
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'エリア移動時');
        close STDOUT;
    }
    
    is scalar $manager->saves->@*, 1, 'auto-saved on area transition';
};

# Test multiple auto_saves
subtest 'multiple auto_saves' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # First auto-save
    $player->hp(100);
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint 1');
        close STDOUT;
    }
    
    # Second auto-save
    $player->hp(70);
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint 2');
        close STDOUT;
    }
    
    # Third auto-save
    $player->hp(40);
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint 3');
        close STDOUT;
    }
    
    is scalar $manager->saves->@*, 3, 'multiple auto-saves work';
    is $manager->saves->[0]->hp, 100, 'first save';
    is $manager->saves->[1]->hp, 70, 'second save';
    is $manager->saves->[2]->hp, 40, 'third save';
};

# Test game flow with auto_save
subtest 'complete game flow with auto_save' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # Start game
    $player->move_to('森');
    $player->hp(70);
    
    # Auto-save at checkpoint
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'checkpoint');
        close STDOUT;
    }
    
    my $checkpoint_slot = scalar $manager->saves->@* - 1;
    
    # Continue and die
    $player->hp(0);
    ok !$player->is_alive, 'player died';
    
    # Load from auto-save
    $manager->load_game($player, $checkpoint_slot);
    ok $player->is_alive, 'restored from auto-save';
    is $player->hp, 70, 'HP restored';
};

# Test toggling auto_save during gameplay
subtest 'toggle auto_save during gameplay' => sub {
    my $manager = GameManager->new;
    my $player = Player->new;
    
    # With auto-save enabled
    ok $manager->auto_save, 'auto-save starts enabled';
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'test 1');
        close STDOUT;
    }
    is scalar $manager->saves->@*, 1, 'saved with auto-save on';
    
    # Disable auto-save
    $manager->auto_save(0);
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'test 2');
        close STDOUT;
    }
    is scalar $manager->saves->@*, 1, 'did not save with auto-save off';
    
    # Re-enable auto-save
    $manager->auto_save(1);
    {
        local *STDOUT;
        open STDOUT, '>', \my $output or die;
        $manager->try_auto_save($player, 'test 3');
        close STDOUT;
    }
    is scalar $manager->saves->@*, 2, 'saved again with auto-save on';
};

done_testing;
