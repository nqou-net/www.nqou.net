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
        
        say $actor->name . "の攻撃！ " . $target->name . "に " . $actual . " のダメージ！";
    }
}

package BattleState {
    use Moo::Role;
    requires 'enter';
    requires 'execute';
    requires 'exit';
}

package BattleContext {
    use Moo;
    
    has player => (
        is       => 'ro',
        required => 1,
    );
    
    has enemy => (
        is       => 'ro',
        required => 1,
    );
    
    has current_state => (
        is      => 'rw',
        default => sub { undef },
    );
    
    has is_finished => (
        is      => 'rw',
        default => 0,
    );
    
    sub change_state($self, $new_state) {
        $self->current_state->exit($self) if $self->current_state;
        $self->current_state($new_state);
        $new_state->enter($self);
    }
    
    sub update($self) {
        return if $self->is_finished;
        $self->current_state->execute($self) if $self->current_state;
    }
}

package BattleStartState {
    use Moo;
    with 'BattleState';
    
    sub enter($self, $context) {
        say "=== 戦闘開始！ ===";
        say $context->enemy->name . "が現れた！";
    }
    
    sub execute($self, $context) {
        say "";
        say $context->player->name . " HP: " . $context->player->hp;
        say $context->enemy->name . " HP: " . $context->enemy->hp;
        say "";
        $context->change_state(PlayerTurnState->new());
    }
    
    sub exit($self, $context) {}
}

package PlayerTurnState {
    use Moo;
    with 'BattleState';
    
    sub enter($self, $context) {
        say "--- " . $context->player->name . "のターン ---";
    }
    
    sub execute($self, $context) {
        my $command = AttackCommand->new(
            actor  => $context->player,
            target => $context->enemy,
        );
        $command->execute();
        
        unless ($context->enemy->is_alive) {
            $context->change_state(BattleEndState->new(winner => 'player'));
            return;
        }
        
        $context->change_state(EnemyTurnState->new());
    }
    
    sub exit($self, $context) {}
}

package EnemyTurnState {
    use Moo;
    with 'BattleState';
    
    sub enter($self, $context) {
        say "";
        say "--- " . $context->enemy->name . "のターン ---";
    }
    
    sub execute($self, $context) {
        my $command = AttackCommand->new(
            actor  => $context->enemy,
            target => $context->player,
        );
        $command->execute();
        
        unless ($context->player->is_alive) {
            $context->change_state(BattleEndState->new(winner => 'enemy'));
            return;
        }
        
        $context->change_state(PlayerTurnState->new());
    }
    
    sub exit($self, $context) {}
}

package BattleEndState {
    use Moo;
    with 'BattleState';
    
    has winner => (
        is       => 'ro',
        required => 1,
    );
    
    sub enter($self, $context) {
        say "";
        say "=== 戦闘終了！ ===";
    }
    
    sub execute($self, $context) {
        if ($self->winner eq 'player') {
            say $context->enemy->name . "を倒した！";
        } else {
            say $context->player->name . "は倒れた...";
        }
        $context->is_finished(1);
    }
    
    sub exit($self, $context) {}
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

my $battle = BattleContext->new(
    player => $hero,
    enemy  => $slime,
);

$battle->change_state(BattleStartState->new());

while (!$battle->is_finished) {
    $battle->update();
}
