#!/usr/bin/env perl
use v5.36;

package Subject {
    use Moo::Role;
    
    has observers => (
        is      => 'ro',
        default => sub { [] },
    );
    
    sub attach($self, $observer) {
        push $self->observers->@*, $observer;
    }
    
    sub detach($self, $observer) {
        $self->observers->@* = grep { $_ != $observer } $self->observers->@*;
    }
    
    sub notify($self, $event, $data = {}) {
        for my $observer ($self->observers->@*) {
            $observer->update($event, $data);
        }
    }
}

package Observer {
    use Moo::Role;
    requires 'update';
}

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
    
    has battle => (
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
        
        if ($self->battle) {
            $self->battle->notify('damage_taken', {
                target => $target,
                damage => $actual,
                message => $msg,
            });
        }
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
        my $old_hp = $actor->hp;
        my $new_hp = $old_hp + $self->heal_amount;
        $actor->hp($new_hp > $max_hp ? $max_hp : $new_hp);
        my $actual_heal = $actor->hp - $old_hp;
        
        say $actor->name . "は" . $self->item_name . "を使った！ HPが " . $actual_heal . " 回復！";
        
        if ($self->battle) {
            $self->battle->notify('heal_received', {
                target => $actor,
                amount => $actual_heal,
            });
        }
    }
}

package BattleLogger {
    use Moo;
    with 'Observer';
    
    has logs => (
        is      => 'ro',
        default => sub { [] },
    );
    
    sub update($self, $event, $data) {
        my $message = $data->{message} // '';
        push $self->logs->@*, "[$event] $message";
    }
    
    sub dump_logs($self) {
        say "=== 戦闘ログ（" . scalar($self->logs->@*) . "件）===";
        say $_ for $self->logs->@*;
    }
}

package DamageEffect {
    use Moo;
    with 'Observer';
    
    sub update($self, $event, $data) {
        return unless $event eq 'damage_taken';
        
        my $target = $data->{target};
        my $hp_ratio = $target->hp / $target->max_hp;
        
        if ($hp_ratio <= 0 ) {
            say "  ★★★ " . $target->name . "は倒れた！ ★★★";
        } elsif ($hp_ratio <= 0.25) {
            say "  ★ " . $target->name . "は瀕死だ！";
        } elsif ($hp_ratio <= 0.5) {
            say "  ※ " . $target->name . "のHPが半分以下！";
        }
    }
}

package BattleReward {
    use Moo;
    with 'Observer';
    
    sub update($self, $event, $data) {
        return unless $event eq 'battle_end';
        return unless $data->{winner} eq 'player';
        
        my $exp = int(rand(50)) + 10;
        my $gold = int(rand(30)) + 5;
        
        say "";
        say "*** " . $exp . " の経験値を獲得！ ***";
        say "*** " . $gold . " ゴールドを獲得！ ***";
    }
}

package BattleContext {
    use Moo;
    with 'Subject';
    
    has player => (
        is       => 'ro',
        required => 1,
    );
    
    has enemy => (
        is       => 'ro',
        required => 1,
    );
    
    has is_finished => (
        is      => 'rw',
        default => 0,
    );
}

# メイン処理
my $hero = Character->new(
    name         => '勇者',
    hp           => 100,
    max_hp       => 100,
    attack_power => 15,
);

my $slime = Character->new(
    name         => 'スライム',
    hp           => 40,
    max_hp       => 40,
    attack_power => 8,
);

my $battle = BattleContext->new(
    player => $hero,
    enemy  => $slime,
);

# Observerを登録
my $logger = BattleLogger->new();
my $damage_effect = DamageEffect->new();
my $reward = BattleReward->new();

$battle->attach($logger);
$battle->attach($damage_effect);
$battle->attach($reward);

# 戦闘開始
say "=== 戦闘開始！ ===";
$battle->notify('battle_start', { message => '戦闘開始' });
say $hero->name . " HP: " . $hero->hp . "  vs  " . $slime->name . " HP: " . $slime->hp;
say "";

# 戦闘ループ
my $turn = 0;
while ($hero->is_alive && $slime->is_alive) {
    $turn++;
    say "--- ターン $turn ---";
    
    # プレイヤーターン
    AttackCommand->new(actor => $hero, target => $slime, battle => $battle)->execute();
    last unless $slime->is_alive;
    
    # 敵ターン
    AttackCommand->new(actor => $slime, target => $hero, battle => $battle)->execute();
}

# 戦闘終了
say "";
say "=== 戦闘終了！ ===";
my $winner = $hero->is_alive ? 'player' : 'enemy';
$battle->notify('battle_end', { winner => $winner, message => '戦闘終了' });

if ($winner eq 'player') {
    say $slime->name . "を倒した！";
} else {
    say $hero->name . "は倒れた...";
}

# ログを出力
say "";
$logger->dump_logs();
