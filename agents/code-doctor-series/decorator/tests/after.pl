#!/usr/bin/env perl
use v5.36;
use utf8;

# --- Doctor's Prescription: Decorator Pattern ---

# 1. Component (Interface/Base)
package Weapon {
    sub new    ($class) { bless {}, $class }
    sub attack ($self)  {10}
    sub name   ($self)  {"Sword"}
}

# 2. Decorator Base
# Holds a reference to a Component (has-a)
package WeaponDecorator {

    sub new ($class, %args) {
        my $self = bless {%args}, $class;

        # Validating that component is defined and behaves like a Weapon
        die "Component is required" unless $self->{component};
        return $self;
    }

    # Delegate by default
    sub attack ($self) { $self->{component}->attack() }
    sub name   ($self) { $self->{component}->name() }
}

# 3. Concrete Decorators
package FireAttribute {
    use parent -norequire, 'WeaponDecorator';

    sub attack ($self) {

        # Original attack + Fire damage
        return $self->SUPER::attack() + 5;
    }

    sub name ($self) {
        return "Fire " . $self->SUPER::name();
    }
}

package IceAttribute {
    use parent -norequire, 'WeaponDecorator';

    sub attack ($self) {
        return $self->SUPER::attack() + 5;
    }

    sub name ($self) {
        return "Ice " . $self->SUPER::name();
    }
}

package LegendaryAttribute {
    use parent -norequire, 'WeaponDecorator';

    sub attack ($self) {

        # Multiplies damage!
        return $self->SUPER::attack() * 2;
    }

    sub name ($self) {
        return "Legendary " . $self->SUPER::name();
    }
}

# --- Usage (The "Surgery" Result) ---

# Base weapon
my $sword = Weapon->new;
say "Base: " . $sword->name . " (Atk: " . $sword->attack . ")";

# Add Fire
my $fire_sword = FireAttribute->new(component => $sword);
say "1. " . $fire_sword->name . " (Atk: " . $fire_sword->attack . ")";

# Add Ice to the Fire Sword (Dynamic Composition)
my $fire_ice_sword = IceAttribute->new(component => $fire_sword);
say "2. " . $fire_ice_sword->name . " (Atk: " . $fire_ice_sword->attack . ")";

# Make it Legendary (Applies to the whole stack)
# Order matters: (10 + 5 + 5) * 2 = 40
my $legendary_sword = LegendaryAttribute->new(component => $fire_ice_sword);
say "3. " . $legendary_sword->name . " (Atk: " . $legendary_sword->attack . ")";

# Alternative Order: Legendary base, then elements
# ((10 * 2) + 5 + 5) = 30
my $base_legend = LegendaryAttribute->new(component => Weapon->new);
my $alt_sword   = IceAttribute->new(component => FireAttribute->new(component => $base_legend));
say "4. " . $alt_sword->name . " (Atk: " . $alt_sword->attack . ")";
