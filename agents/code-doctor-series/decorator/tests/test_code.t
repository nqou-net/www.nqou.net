#!/usr/bin/env perl
use v5.36;
use Test::More;

# --- Define Classes for Testing (Copy of After Logic) ---

package Weapon {
    sub new    ($class) { bless {}, $class }
    sub attack ($self)  {10}
    sub name   ($self)  {"Sword"}
}

package WeaponDecorator {

    sub new ($class, %args) {
        my $self = bless {%args}, $class;
        die "Component is required" unless $self->{component};
        return $self;
    }
    sub attack ($self) { $self->{component}->attack() }
    sub name   ($self) { $self->{component}->name() }
}

package FireAttribute {
    use parent -norequire, 'WeaponDecorator';
    sub attack ($self) { $self->SUPER::attack() + 5 }
    sub name   ($self) { "Fire " . $self->SUPER::name() }
}

package IceAttribute {
    use parent -norequire, 'WeaponDecorator';
    sub attack ($self) { $self->SUPER::attack() + 5 }
    sub name   ($self) { "Ice " . $self->SUPER::name() }
}

package LegendaryAttribute {
    use parent -norequire, 'WeaponDecorator';
    sub attack ($self) { $self->SUPER::attack() * 2 }
    sub name   ($self) { "Legendary " . $self->SUPER::name() }
}

# --- Tests ---

subtest 'Base Weapon' => sub {
    my $w = Weapon->new;
    is $w->attack, 10,      'Base attack';
    is $w->name,   'Sword', 'Base name';
};

subtest 'Single Decoration' => sub {
    my $w = FireAttribute->new(component => Weapon->new);
    is $w->attack, 15,           'Fire attack (10+5)';
    is $w->name,   'Fire Sword', 'Fire name';
};

subtest 'Nested Decoration' => sub {
    my $w = IceAttribute->new(component => FireAttribute->new(component => Weapon->new));
    is $w->attack, 20,               'Fire+Ice attack (10+5+5)';
    is $w->name,   'Ice Fire Sword', 'Ice Fire name';
};

subtest 'Multiplication Decoration (Legendary)' => sub {

    # Order: (Base + Fire + Ice) * Legendary
    my $base   = IceAttribute->new(component => FireAttribute->new(component => Weapon->new));
    my $legend = LegendaryAttribute->new(component => $base);

    # (10 + 5 + 5) * 2 = 40
    is $legend->attack, 40,                         'Legendary(Fire+Ice) attack';
    is $legend->name,   'Legendary Ice Fire Sword', 'Legendary name';
};

subtest 'Order Matters' => sub {

    # Order: ((Base * Legendary) + Fire + Ice)
    my $base_legend = LegendaryAttribute->new(component => Weapon->new);                               # 10 * 2 = 20
    my $w           = IceAttribute->new(component => FireAttribute->new(component => $base_legend));

    # 20 + 5 + 5 = 30
    is $w->attack, 30, 'Ice+Fire+Legendary(Base) attack';
};

done_testing;
