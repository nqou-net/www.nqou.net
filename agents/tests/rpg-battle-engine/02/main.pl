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
    
    has is_defending => (
        is      => 'rw',
        default => 0,
    );
    
    sub is_alive($self) {
        return $self->hp > 0;
    }
    
    sub take_damage($self, $damage) {
        my $actual_damage = $self->is_defending ? int($damage / 2) : $damage;
        my $new_hp = $self->hp - $actual_damage;
        $self->hp($new_hp < 0 ? 0 : $new_hp);
        $self->is_defending(0);
        return $actual_damage;
    }
}

package Action {
    use Moo;
    
    has actor => (
        is       => 'ro',
        required => 1,
    );
    
    sub execute($self, $target) {
        die "execute() must be implemented by subclass";
    }
}

package AttackAction {
    use Moo;
    extends 'Action';
    
    sub execute($self, $target) {
        my $actor = $self->actor;
        my $damage = $actor->attack_power;
        my $actual = $target->take_damage($damage);
        
        my $msg = $actor->name . "の攻撃！ " . $target->name . "に " . $actual . " のダメージ！";
        $msg .= "（防御で軽減）" if $actual < $damage;
        say $msg;
    }
}

package DefendAction {
    use Moo;
    extends 'Action';
    
    sub execute($self, $target) {
        my $actor = $self->actor;
        $actor->is_defending(1);
        say $actor->name . "は防御の構えをとった！";
    }
}

package ItemAction {
    use Moo;
    extends 'Action';
    
    has item_name => (
        is      => 'ro',
        default => 'ポーション',
    );
    
    has heal_amount => (
        is      => 'ro',
        default => 30,
    );
    
    sub execute($self, $target) {
        my $actor = $self->actor;
        my $max_hp = 100;
        my $new_hp = $actor->hp + $self->heal_amount;
        $actor->hp($new_hp > $max_hp ? $max_hp : $new_hp);
        
        say $actor->name . "は" . $self->item_name . "を使った！ HPが " . $self->heal_amount . " 回復！";
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
    hp           => 50,
    attack_power => 10,
);

say "=== 戦闘デモ ===";
say "勇者 HP: " . $hero->hp . "  スライム HP: " . $slime->hp;
say "";

# ターン1: 勇者は攻撃、スライムは防御
AttackAction->new(actor => $hero)->execute($slime);
DefendAction->new(actor => $slime)->execute($slime);

say "";

# ターン2: 勇者は攻撃（スライムは防御中）、スライムはアイテム
AttackAction->new(actor => $hero)->execute($slime);
ItemAction->new(actor => $slime, heal_amount => 20)->execute($slime);

say "";
say "最終状態: 勇者 HP: " . $hero->hp . "  スライム HP: " . $slime->hp;
