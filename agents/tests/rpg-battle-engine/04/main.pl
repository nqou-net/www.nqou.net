#!/usr/bin/env perl
use v5.36;

package Command {
    use Moo::Role;
    
    requires 'execute';
    
    has actor => (
        is       => 'ro',
        required => 1,
    );
    
    has target => (
        is       => 'ro',
        required => 0,
    );
}

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
    
    has max_hp => (
        is      => 'ro',
        default => 100,
    );
    
    has mp => (
        is      => 'rw',
        default => 50,
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

package AttackCommand {
    use Moo;
    with 'Command';
    
    sub execute($self) {
        my $actor = $self->actor;
        my $target = $self->target;
        my $damage = $actor->attack_power;
        my $actual = $target->take_damage($damage);
        
        my $msg = $actor->name . "の攻撃！ " . $target->name . "に " . $actual . " のダメージ！";
        $msg .= "（防御で軽減）" if $actual < $damage;
        say $msg;
    }
}

package DefendCommand {
    use Moo;
    with 'Command';
    
    sub execute($self) {
        my $actor = $self->actor;
        $actor->is_defending(1);
        say $actor->name . "は防御の構えをとった！";
    }
}

package ItemCommand {
    use Moo;
    with 'Command';
    
    has item_name => (
        is      => 'ro',
        default => 'ポーション',
    );
    
    has heal_amount => (
        is      => 'ro',
        default => 30,
    );
    
    sub execute($self) {
        my $actor = $self->actor;
        my $max_hp = $actor->max_hp;
        my $new_hp = $actor->hp + $self->heal_amount;
        $actor->hp($new_hp > $max_hp ? $max_hp : $new_hp);
        
        say $actor->name . "は" . $self->item_name . "を使った！ HPが " . $self->heal_amount . " 回復！";
    }
}

package MagicCommand {
    use Moo;
    with 'Command';
    
    has spell_name => (
        is      => 'ro',
        default => 'ファイアボール',
    );
    
    has damage => (
        is      => 'ro',
        default => 25,
    );
    
    has mp_cost => (
        is      => 'ro',
        default => 10,
    );
    
    sub execute($self) {
        my $actor = $self->actor;
        my $target = $self->target;
        
        if ($actor->mp < $self->mp_cost) {
            say $actor->name . "はMPが足りない！";
            return;
        }
        
        $actor->mp($actor->mp - $self->mp_cost);
        my $actual = $target->take_damage($self->damage);
        
        say $actor->name . "は" . $self->spell_name . "を唱えた！ " . $target->name . "に " . $actual . " のダメージ！";
    }
}

package CommandInvoker {
    use Moo;
    
    has history => (
        is      => 'ro',
        default => sub { [] },
    );
    
    sub invoke($self, $command) {
        push $self->history->@*, $command;
        $command->execute();
    }
}

# メイン処理
my $hero = Character->new(
    name         => '勇者',
    hp           => 100,
    max_hp       => 100,
    mp           => 50,
    attack_power => 15,
);

my $slime = Character->new(
    name         => 'スライム',
    hp           => 50,
    max_hp       => 50,
    attack_power => 10,
);

my $invoker = CommandInvoker->new();

say "=== Commandパターンによる戦闘デモ ===";
say "勇者 HP: " . $hero->hp . " MP: " . $hero->mp;
say "スライム HP: " . $slime->hp;
say "";

# 各種コマンドを実行
$invoker->invoke(AttackCommand->new(actor => $hero, target => $slime));
$invoker->invoke(DefendCommand->new(actor => $slime));
$invoker->invoke(MagicCommand->new(actor => $hero, target => $slime, spell_name => 'ファイアボール', damage => 25, mp_cost => 10));

say "";
say "=== 戦闘履歴 ===";
say "実行されたコマンド数: " . scalar($invoker->history->@*);

say "";
say "最終状態:";
say "勇者 HP: " . $hero->hp . " MP: " . $hero->mp;
say "スライム HP: " . $slime->hp;
