use v5.36;
use experimental qw( builtin );
use builtin      qw( true false );

# --- Enemies ---

package Enemy::Slime {
    sub new    ($class) { bless {name => 'Slime', hp => 10}, $class }
    sub scream ($self)  {"Puru-puru!"}
}

package Enemy::Dragon {
    sub new    ($class) { bless {name => 'Dragon', hp => 500}, $class }
    sub scream ($self)  {"Gaooo!"}
}

package Enemy::Goblin {
    sub new    ($class) { bless {name => 'Goblin', hp => 30}, $class }
    sub scream ($self)  {"Gegya!"}
}

# --- Good Code: Factory Method (Simple Factory variant with Registry) ---

package EnemyFactory {

    # Private registry to store mappings
    my %registry;

    sub register ($class, $type, $target_class) {
        $registry{$type} = $target_class;
        say "Factory: Registered '$type' => $target_class";
    }

    sub create ($class, $type) {
        my $target_class = $registry{$type};
        unless ($target_class) {
            die "Factory Error: No class registered for '$type'";
        }
        return $target_class->new;
    }
}

# --- Game Class (Cured) ---

package Game {
    sub new ($class) { bless {}, $class }

    sub spawn_enemy ($self, $type) {

        # Cure: No more if/else here. Delegation to Factory.
        my $enemy = EnemyFactory->create($type);

        say "Spawned: " . $enemy->{name} . " (HP: " . $enemy->{hp} . ")";
        say "Sound: " . $enemy->scream;
        return $enemy;
    }
}

# --- Client Code / Setup ---

# 1. Configuration (can be in a config file or init script)
EnemyFactory->register('slime',  'Enemy::Slime');
EnemyFactory->register('dragon', 'Enemy::Dragon');
EnemyFactory->register('goblin', 'Enemy::Goblin');

# 2. Game Logic
my $game = Game->new;
$game->spawn_enemy('slime');
$game->spawn_enemy('dragon');

# 3. Adding a new monster (MetalSlime) does NOT touch Game.pm!
# We just define the class and register it.
package Enemy::MetalSlime {
    sub new    ($class) { bless {name => 'Metal Slime', hp => 4}, $class }
    sub scream ($self)  {"Kira-kira!"}
}
EnemyFactory->register('metal_slime', 'Enemy::MetalSlime');

$game->spawn_enemy('metal_slime');
