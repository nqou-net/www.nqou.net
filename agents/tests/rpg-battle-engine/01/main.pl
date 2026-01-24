#!/usr/bin/env perl
use v5.36;

package Character {
    use Moo;
    
    has name => (
        is       => 'ro',
        required => 1,
    );
    
    has hp => (
        is      => 'rw',
        default => 100,
    );
    
    has attack_power => (
        is      => 'ro',
        default => 10,
    );
    
    sub attack($self, $target) {
        my $damage = $self->attack_power;
        my $new_hp = $target->hp - $damage;
        $target->hp($new_hp < 0 ? 0 : $new_hp);
        
        say $self->name . "の攻撃！ " . $target->name . "に " . $damage . " のダメージ！";
    }
    
    sub is_alive($self) {
        return $self->hp > 0;
    }
}

sub battle($player, $enemy) {
    say "=== 戦闘開始！ ===";
    say $player->name . " HP: " . $player->hp . "  vs  " . $enemy->name . " HP: " . $enemy->hp;
    say "";
    
    while ($player->is_alive && $enemy->is_alive) {
        $player->attack($enemy);
        last unless $enemy->is_alive;
        
        $enemy->attack($player);
    }
    
    say "";
    if ($player->is_alive) {
        say $enemy->name . "を倒した！";
    } else {
        say $player->name . "は倒れた...";
    }
}

# メイン処理
my $hero = Character->new(
    name         => '勇者',
    hp           => 100,
    attack_power => 15,
);

my $slime = Character->new(
    name         => 'スライム',
    hp           => 30,
    attack_power => 5,
);

battle($hero, $slime);
