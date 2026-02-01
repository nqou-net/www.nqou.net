#!/usr/bin/env perl
use v5.36;

# === 製品インターフェース（Role） ===
package FlavorProfile::Role {
    use Moo::Role;
    requires 'get_nose';
    requires 'get_palate';
    requires 'get_finish';
}

package TastingCard::Role {
    use Moo::Role;
    requires 'render';
}

package Pairing::Role {
    use Moo::Role;
    requires 'suggest';
}

# === スコッチ製品 ===
package ScotchProfile {
    use Moo;
    with 'FlavorProfile::Role';
    
    sub get_nose($self)   { return 'smoky, peaty, maritime' }
    sub get_palate($self) { return 'intense smoke, brine, pepper' }
    sub get_finish($self) { return 'long, warming, peaty' }
}

package ScotchCard {
    use Moo;
    with 'TastingCard::Role';
    
    has profile => (is => 'ro', required => 1);
    has name    => (is => 'ro', required => 1);
    
    sub render($self) {
        my $p = $self->profile;
        return join("\n",
            "┏━━━ SCOTCH TASTING CARD ━━━┓",
            "┃ " . $self->name,
            "┃ Nose: " . $p->get_nose,
            "┃ Palate: " . $p->get_palate,
            "┃ Finish: " . $p->get_finish,
            "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛",
        );
    }
}

package ScotchPairing {
    use Moo;
    with 'Pairing::Role';
    
    sub suggest($self) {
        return ['Blue cheese', 'Smoked salmon', 'Dark chocolate'];
    }
}

# === アイリッシュ製品 ===
package IrishProfile {
    use Moo;
    with 'FlavorProfile::Role';
    
    sub get_nose($self)   { return 'fruity, honey, vanilla' }
    sub get_palate($self) { return 'smooth, creamy, spice' }
    sub get_finish($self) { return 'warm, gentle, sweet' }
}

package IrishCard {
    use Moo;
    with 'TastingCard::Role';
    
    has profile => (is => 'ro', required => 1);
    has name    => (is => 'ro', required => 1);
    
    sub render($self) {
        my $p = $self->profile;
        return join("\n",
            "╭──── IRISH TASTING CARD ────╮",
            "│ " . $self->name,
            "│ Nose: " . $p->get_nose,
            "│ Palate: " . $p->get_palate,
            "│ Finish: " . $p->get_finish,
            "╰────────────────────────────╯",
        );
    }
}

package IrishPairing {
    use Moo;
    with 'Pairing::Role';
    
    sub suggest($self) {
        return ['Irish stew', 'Soda bread', 'Apple pie'];
    }
}

# === Abstract Factory ===
package TastingKitFactory::Role {
    use Moo::Role;
    requires 'create_profile';
    requires 'create_card';
    requires 'create_pairing';
}

package ScotchFactory {
    use Moo;
    with 'TastingKitFactory::Role';
    
    sub create_profile($self) { return ScotchProfile->new }
    
    sub create_card($self, $name) {
        return ScotchCard->new(
            name    => $name,
            profile => $self->create_profile,
        );
    }
    
    sub create_pairing($self) { return ScotchPairing->new }
}

package IrishFactory {
    use Moo;
    with 'TastingKitFactory::Role';
    
    sub create_profile($self) { return IrishProfile->new }
    
    sub create_card($self, $name) {
        return IrishCard->new(
            name    => $name,
            profile => $self->create_profile,
        );
    }
    
    sub create_pairing($self) { return IrishPairing->new }
}

# === メイン処理 ===
package main {
    sub create_tasting_kit($factory, $whisky_name) {
        my $card    = $factory->create_card($whisky_name);
        my $pairing = $factory->create_pairing;
        return ($card, $pairing);
    }
    
    # スコッチのキットを作成
    my $scotch_factory = ScotchFactory->new;
    my ($card, $pairing) = create_tasting_kit($scotch_factory, 'Laphroaig 10');
    
    say $card->render;
    say "Pairing: " . join(", ", $pairing->suggest->@*);
    say "";
    
    # アイリッシュのキットを作成
    my $irish_factory = IrishFactory->new;
    ($card, $pairing) = create_tasting_kit($irish_factory, 'Redbreast 12');
    
    say $card->render;
    say "Pairing: " . join(", ", $pairing->suggest->@*);
}
