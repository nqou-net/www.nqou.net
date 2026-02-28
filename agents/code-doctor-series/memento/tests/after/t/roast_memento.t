#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use RoastManager;
use RoastHistory;

subtest '初期プロファイルの確認' => sub {
    my $mgr = RoastManager->new();
    my $p   = $mgr->profile;
    is $p->{temp_start}, 180, '初期温度は180';
    is $p->{temp_peak},  220, 'ピーク温度は220';
    is $p->{duration},   720, '焙煎時間は720秒';
    is $p->{fan_speed},  65,  'ファン速度は65%';
};

subtest 'Mementoで状態を保存・復元できる' => sub {
    my $mgr     = RoastManager->new();
    my $history = RoastHistory->new();

    # 初期状態を保存
    $history->save($mgr->save_to_memento('初期設定'));

    # 最高の焙煎設定を発見！
    $mgr->update_profile(temp_peak => 215, duration => 660);
    $history->save($mgr->save_to_memento('最高の一杯'));

    # さらに実験……
    $mgr->update_profile(temp_peak => 225, duration => 780);
    $history->save($mgr->save_to_memento('実験3回目'));

    is $mgr->profile->{temp_peak}, 225, '現在は225';

    # 「あの時の215に戻したい！」
    # 最新のスナップショット(実験3回目)を取り出して、一つ前に戻す
    $history->undo();  # 実験3回目を捨てる
    my $best = $history->undo();  # 最高の一杯を取り出す
    $mgr->restore_from_memento($best);

    is $mgr->profile->{temp_peak}, 215, 'あの日の設定に戻れた！';
    is $mgr->profile->{duration},  660, '焙煎時間も復元された';
};

subtest '履歴スタックの管理' => sub {
    my $mgr     = RoastManager->new();
    my $history = RoastHistory->new();

    is $history->count, 0, '最初は履歴なし';

    $history->save($mgr->save_to_memento('ver.1'));
    $history->save($mgr->save_to_memento('ver.2'));
    $history->save($mgr->save_to_memento('ver.3'));

    is $history->count, 3, '3つのスナップショット';

    my $m = $history->undo();
    is $m->label, 'ver.3', '最新を取り出せる';
    is $history->count, 2, '残り2つ';
};

subtest 'Mementoは深いコピーを保持する' => sub {
    my $mgr = RoastManager->new();

    my $memento = $mgr->save_to_memento('保存時点');

    # 保存後にプロファイルを変更
    $mgr->update_profile(temp_peak => 999);

    # Mementoの中身は変わっていない（深いコピー）
    my $saved_state = $memento->state;
    is $saved_state->{temp_peak}, 220, 'Mementoの値は変わらない';
    is $mgr->profile->{temp_peak}, 999, '現在の値は変更済み';
};

subtest '5つのスナップショットの保存と任意の復元' => sub {
    my $mgr     = RoastManager->new();
    my $history = RoastHistory->new();

    # 5つの異なるプロファイルを保存
    my @profiles = (
        { temp_peak => 210, fan_speed => 60, duration => 600 },
        { temp_peak => 215, fan_speed => 65, duration => 660 },
        { temp_peak => 220, fan_speed => 70, duration => 720 },
        { temp_peak => 225, fan_speed => 75, duration => 780 },
        { temp_peak => 230, fan_speed => 80, duration => 840 },
    );

    for my $i (0 .. $#profiles) {
        $mgr->update_profile($profiles[$i]->%*);
        $history->save($mgr->save_to_memento("試作#" . ($i + 1)));
    }

    is $history->count, 5, '5つのスナップショットが保存された';

    # 最新から3つ戻して試作#2を復元
    $history->undo();  # 試作#5
    $history->undo();  # 試作#4
    $history->undo();  # 試作#3
    my $target = $history->undo();  # 試作#2
    $mgr->restore_from_memento($target);

    is $mgr->profile->{temp_peak}, 215, '試作#2のピーク温度に復元';
    is $mgr->profile->{fan_speed}, 65,  '試作#2のファン速度に復元';
    is $mgr->profile->{duration},  660, '試作#2の焙煎時間に復元';
    is $target->label, '試作#2', 'ラベルも正確';
};

done_testing;
