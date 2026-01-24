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
    
    has attack_power => (
        is      => 'ro',
        default => 10,
    );
    
    has is_defending => (
        is      => 'rw',
        default => 0,
    );
    
    has ai_strategy => (
        is      => 'rw',
        default => sub { undef },
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
    
    sub decide_action($self, $target) {
        die "No AI strategy set" unless $self->ai_strategy;
        return $self->ai_strategy->decide_action($self, $target);
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

package AIStrategy {
    use Moo::Role;
    requires 'decide_action';
}

package AggressiveAI {
    use Moo;
    with 'AIStrategy';
    
    sub decide_action($self, $actor, $target) {
        return AttackCommand->new(
            actor  => $actor,
            target => $target,
        );
    }
}

package DefensiveAI {
    use Moo;
    with 'AIStrategy';
    
    sub decide_action($self, $actor, $target) {
        if ($actor->hp <= $actor->max_hp / 2) {
            return ItemCommand->new(
                actor       => $actor,
                item_name   => 'ポーション',
                heal_amount => 20,
            );
        }
        return AttackCommand->new(
            actor  => $actor,
            target => $target,
        );
    }
}

package RandomAI {
    use Moo;
    with 'AIStrategy';
    
    sub decide_action($self, $actor, $target) {
        my @actions = (
            sub { AttackCommand->new(actor => $actor, target => $target) },
            sub { DefendCommand->new(actor => $actor) },
            sub { ItemCommand->new(actor => $actor, item_name => 'ポーション', heal_amount => 10) },
        );
        
        my $chosen = $actions[int(rand(@actions))];
        return $chosen->();
    }
}

# デモ: 各AIの動作確認
say "=== AI戦略デモ ===";
say "";

my $hero = Character->new(
    name         => '勇者',
    hp           => 100,
    max_hp       => 100,
    attack_power => 15,
);

# 攻撃的AI
say "【攻撃的AI】";
my $goblin = Character->new(
    name         => 'ゴブリン',
    hp           => 50,
    max_hp       => 50,
    attack_power => 8,
    ai_strategy  => AggressiveAI->new(),
);
$goblin->decide_action($hero)->execute();

say "";

# 防御的AI（HPが半分以下）
say "【防御的AI（HP低下時）】";
my $orc = Character->new(
    name         => 'オーク',
    hp           => 20,  # 半分以下
    max_hp       => 50,
    attack_power => 12,
    ai_strategy  => DefensiveAI->new(),
);
$orc->decide_action($hero)->execute();

say "";

# ランダムAI
say "【ランダムAI（3回実行）】";
my $slime = Character->new(
    name         => 'スライム',
    hp           => 30,
    max_hp       => 30,
    attack_power => 5,
    ai_strategy  => RandomAI->new(),
);
for (1..3) {
    $slime->decide_action($hero)->execute();
}
