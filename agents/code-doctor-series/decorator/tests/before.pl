#!/usr/bin/env perl
use v5.36;
use utf8;

# --- Patient's Code: The "Inheritance Hell" ---

# Base Class
package Weapon {
    sub new    ($class, %args) { bless {%args}, $class }
    sub attack ($self)         {10}
    sub name   ($self)         {"Sword"}
}

# 1st Generation (Single Attribute matches)
package FireSword {
    use parent -norequire, 'Weapon';
    sub attack ($self) { $self->SUPER::attack() + 5 }
    sub name   ($self) { "Fire " . $self->SUPER::name() }
}

package IceSword {
    use parent -norequire, 'Weapon';
    sub attack ($self) { $self->SUPER::attack() + 5 }
    sub name   ($self) { "Ice " . $self->SUPER::name() }
}

# 2nd Generation (Combinations)
# PROBLEM: How to combine Fire and Ice?
# Patient's solution: Create a new class manually
package FireIceSword {

    # Which one to inherit? Multiple inheritance? Or just copy-paste?
    # Patient chose copy-paste logic (simulating the mess)
    use parent -norequire, 'Weapon';

    sub attack ($self) {

        # Hardcoded 10 + 5 + 5
        20;
    }
    sub name ($self) {"Fire Ice Sword"}
}

package DurableFireSword {
    use parent -norequire, 'FireSword';
    sub name ($self) { "Durable " . $self->SUPER::name() }

    # Durability logic mixed in...
}

# Usage
my $fire_sword = FireSword->new;
say "Name: " . $fire_sword->name;      # Fire Sword
say "Atk:  " . $fire_sword->attack;    # 15

my $chaos_sword = FireIceSword->new;
say "Name: " . $chaos_sword->name;      # Fire Ice Sword
say "Atk:  " . $chaos_sword->attack;    # 20
