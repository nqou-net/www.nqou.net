use v5.36;
use utf8;
use open qw(:std :utf8);

# Doctor's Code: "Abstract Factory Pattern"
# 処方: 関連するオブジェクト（武器・防具）の生成ルールを「工場（Factory）」としてカプセル化する。
# 効果: クライアントコードは「具体的なクラス名」を知らなくて済む。
#       新しい職業を追加しても、既存のコード（Factory呼び出し部分）は修正不要。

# --- Abstract Products ---
package Game::Weapon {
    sub attack($self) { die "Override me" }
}

package Game::Armor {
    sub defend($self) { die "Override me" }
}

# --- Concrete Products ---
package Game::Weapon::Sword {
    use parent -norequire, 'Game::Weapon';
    sub new($class)   { bless {}, $class }
    sub attack($self) {"Slash with Sword!"}
}

package Game::Weapon::Staff {
    use parent -norequire, 'Game::Weapon';
    sub new($class)   { bless {}, $class }
    sub attack($self) {"Cast spell with Staff!"}
}

package Game::Armor::Plate {
    use parent -norequire, 'Game::Armor';
    sub new($class)   { bless {}, $class }
    sub defend($self) {"Block with Plate Armor"}
}

package Game::Armor::Robe {
    use parent -norequire, 'Game::Armor';
    sub new($class)   { bless {}, $class }
    sub defend($self) {"Absorb magic with Robe"}
}

# --- Abstract Factory ---
package Game::Factory {

    # Interface definition
    sub create_weapon($self) { die "Abstract" }
    sub create_armor($self)  { die "Abstract" }
}

# --- Concrete Factories ---
package Game::Factory::Warrior {
    use parent -norequire, 'Game::Factory';
    sub new($class) { bless {}, $class }

    # Warrior用の製品セットを生成
    sub create_weapon($self) { Game::Weapon::Sword->new }
    sub create_armor($self)  { Game::Armor::Plate->new }
}

package Game::Factory::Mage {
    use parent -norequire, 'Game::Factory';
    sub new($class) { bless {}, $class }

    # Mage用の製品セットを生成
    sub create_weapon($self) { Game::Weapon::Staff->new }
    sub create_armor($self)  { Game::Armor::Robe->new }
}

# --- Client ---
package Game::Character {

    sub new($class, $factory) {
        my $self = bless {}, $class;

        # 工場を使って装備を整える（具体的なクラス名は知らない）
        $self->{weapon} = $factory->create_weapon;
        $self->{armor}  = $factory->create_armor;
        return $self;
    }

    sub show_status($self) {
        my $w_action = $self->{weapon}->attack;
        my $a_action = $self->{armor}->defend;
        return "Action: [$w_action] / Defense: [$a_action]";
    }
}

package main;

say "--- New World (Factory Pattern) ---";

# Client Code は「どの工場を使うか」だけを決める
my $warrior_factory = Game::Factory::Warrior->new;
my $warrior         = Game::Character->new($warrior_factory);
say "[Warrior] " . $warrior->show_status;

my $mage_factory = Game::Factory::Mage->new;
my $mage         = Game::Character->new($mage_factory);
say "[Mage]    " . $mage->show_status;
