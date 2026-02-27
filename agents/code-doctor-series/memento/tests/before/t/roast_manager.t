#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use RoastManager;

subtest '初期プロファイルの確認' => sub {
    my $mgr = RoastManager->new();
    my $p   = $mgr->profile;
    is $p->{temp_start}, 180, '初期温度は180';
    is $p->{temp_peak},  220, 'ピーク温度は220';
    is $p->{duration},   720, '焙煎時間は720秒';
    is $p->{fan_speed},  65,  'ファン速度は65%';
};

subtest 'プロファイル更新で前の値が消える' => sub {
    my $mgr = RoastManager->new();

    # 最高の焙煎設定を発見！
    $mgr->update_profile(temp_peak => 215, duration => 660);
    is $mgr->profile->{temp_peak}, 215, 'ピーク温度を215に変更';

    # さらに実験……
    $mgr->update_profile(temp_peak => 225, duration => 780);
    is $mgr->profile->{temp_peak}, 225, 'ピーク温度を225に変更';

    # 「あの時の215に戻したい！」 → 戻せない……
    # 前の値 (215) はどこにも残っていない
    isnt $mgr->profile->{temp_peak}, 215, '前の設定には戻せない！';
};

subtest 'save_backupはファイル名を返すだけ' => sub {
    my $mgr = RoastManager->new();
    my $f   = $mgr->save_backup('v2');
    is $f, 'roast_profile_v2.yaml', 'ファイル名が返される';

    # でもどの時点の状態かは誰にも分からない……
    my $f2 = $mgr->save_backup('final');
    is $f2, 'roast_profile_final.yaml', 'finalという名前のbackup';

    # roast_profile_backup.yaml
    # roast_profile_v2.yaml
    # roast_profile_final.yaml
    # roast_profile_best_maybe.yaml ← いつかこうなる
};

done_testing;
