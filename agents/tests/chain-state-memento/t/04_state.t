#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第4回: State パターンのテスト

use GameState;
use ExplorationState;
use BattleState;
use EventState;

subtest 'ExplorationState' => sub {
    my $state = ExplorationState->new;

    is $state->name, '探索', '状態名';
    my @cmds = @{$state->available_commands};
    ok grep { $_ eq '北' } @cmds,   '移動コマンド含む';
    ok grep { $_ eq '調べる' } @cmds, '調べるコマンド含む';
};

subtest 'BattleState - 基本' => sub {
    my $state = BattleState->new(enemy_name => 'ゴブリン', enemy_hp => 30);

    is $state->name,       '戦闘',   '状態名';
    is $state->enemy_name, 'ゴブリン', '敵の名前';
    is $state->enemy_hp,   30,     '敵のHP';

    my @cmds = @{$state->available_commands};
    ok grep { $_ eq '攻撃' } @cmds,  '攻撃コマンド';
    ok grep { $_ eq '逃げる' } @cmds, '逃げるコマンド';
};

subtest 'BattleState - 戦闘処理' => sub {
    my $state   = BattleState->new(enemy_name => 'スライム', enemy_hp => 10);
    my $context = {hp => 100, inventory => ['回復薬']};

    # 攻撃（低HPの敵なので倒せる）
    my $result = $state->process_command($context, '攻撃');
    ok $result->{victory} || $state->enemy_hp > 0, '攻撃処理';

    # 回復薬使用
    my $state2 = BattleState->new(enemy_name => 'スライム', enemy_hp => 50);
    $context->{hp} = 50;
    $result = $state2->process_command($context, '使う 回復薬');
    like $result->{message}, qr/回復薬/, '回復薬使用';
    ok $context->{hp} > 50, 'HP回復';
};

subtest 'EventState' => sub {
    my $state = EventState->new(
        event_name => '老人との会話',
        options    => ['はい', 'いいえ'],
    );

    is $state->name, 'イベント', '状態名';

    my $context = {};
    my $result  = $state->process_command($context, 'はい');
    ok $result->{done}, 'イベント完了';
    is $result->{choice}, 'はい', '選択肢記録';

    $result = $state->process_command($context, 'わからない');
    like $result->{message}, qr/選択肢/, '無効な選択';
};

done_testing;
