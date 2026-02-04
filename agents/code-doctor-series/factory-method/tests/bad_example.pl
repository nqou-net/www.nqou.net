use v5.36;
use experimental qw( builtin );
use builtin      qw( true false );

# --- Bad Code: Game Class with hardcoded dependencies ---

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

package Game {
    sub new ($class) { bless {}, $class }

    sub spawn_enemy ($self, $type) {
        my $enemy;

        # Symptom: Conditional logic explosion
        # If we add a new monster, we MUST modify this class.
        if ($type eq 'slime') {
            $enemy = Enemy::Slime->new;
        }
        elsif ($type eq 'dragon') {
            $enemy = Enemy::Dragon->new;
        }
        elsif ($type eq 'goblin') {
            $enemy = Enemy::Goblin->new;
        }
        else {
            die "Unknown enemy type: $type";
        }

        say "Spawned: " . $enemy->{name} . " (HP: " . $enemy->{hp} . ")";
        say "Sound: " . $enemy->scream;
        return $enemy;
    }
}

# --- Client Code ---
my $game = Game->new;
$game->spawn_enemy('slime');
$game->spawn_enemy('dragon');

# $game->spawn_enemy('metal_slime'); # Dies!
