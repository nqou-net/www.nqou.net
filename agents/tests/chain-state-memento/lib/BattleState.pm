package BattleState;
use v5.36;
use warnings;
use Moo;

with 'GameState';

# 戦闘モード: 攻撃・逃げるなどが可能、移動は不可

has enemy_name => (is => 'ro', required => 1);
has enemy_hp   => (is => 'rw', required => 1);

sub name($self) {'戦闘'}

sub available_commands($self) {
    return ['攻撃', '逃げる', '使う', 'ヘルプ'];
}

sub on_enter($self, $context) {
    return $self->enemy_name . 'が現れた！戦闘開始！';
}

sub process_command($self, $context, $command) {
    if ($command eq '攻撃') {
        my $damage = int(rand(20)) + 10;
        $self->enemy_hp($self->enemy_hp - $damage);

        if ($self->enemy_hp <= 0) {
            return {
                message => $self->enemy_name . 'に' . $damage . 'のダメージ！' . $self->enemy_name . 'を倒した！',
                victory => 1,
            };
        }

        # 敵の反撃
        my $counter = int(rand(10)) + 5;
        $context->{hp} -= $counter;

        return {message => $self->enemy_name . 'に' . $damage . 'のダメージ！' . '反撃で' . $counter . 'ダメージを受けた。HP: ' . $context->{hp},};
    }
    elsif ($command eq '逃げる') {
        return {
            message => '逃げ出した！',
            fled    => 1,
        };
    }
    elsif ($command =~ /^使う\s+(.+)$/) {
        my $item      = $1;
        my $inventory = $context->{inventory} //= [];

        my $idx = -1;
        for my $i (0 .. $#$inventory) {
            if ($inventory->[$i] eq $item) {
                $idx = $i;
                last;
            }
        }

        if ($idx >= 0 && $item eq '回復薬') {
            splice(@$inventory, $idx, 1);
            $context->{hp} += 30;
            $context->{hp} = 100 if $context->{hp} > 100;
            return {message => '回復薬を使った。HP: ' . $context->{hp}};
        }

        return {message => $idx >= 0 ? 'それは戦闘では使えない。' : 'そのアイテムは持っていない。'};
    }
    elsif ($command eq 'ヘルプ') {
        return {message => '戦闘中！「攻撃」「逃げる」「使う アイテム名」が使えます。'};
    }
    else {
        return {message => '戦闘中はそのコマンドは使えない！'};
    }
}

1;
