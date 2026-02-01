#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 第5回: Memento パターンのテスト

use GameMemento;
use SaveManager;

subtest 'GameMemento - 基本' => sub {
    my $state = {
        location  => '森の入り口',
        hp        => 100,
        inventory => ['鍵', '薬'],
    };

    my $memento = GameMemento->new(state => $state, label => 'テストセーブ');

    like $memento->describe, qr/森の入り口/, '場所が含まれる';
    like $memento->describe, qr/100/,   'HPが含まれる';

    # 元の状態を変更してもメメントは影響なし（ディープコピー）
    $state->{location} = '別の場所';
    $state->{hp}       = 50;

    my $restored = $memento->get_state;
    is $restored->{location}, '森の入り口', 'ディープコピーで独立';
    is $restored->{hp},       100,     'HPも独立';
};

subtest 'SaveManager - セーブ/ロード' => sub {
    my $manager = SaveManager->new;

    is scalar(@{$manager->saves}), 0, '初期状態は空';

    my $context = {location => '小道', hp => 80, inventory => []};
    $manager->save($context, 'セーブ1');

    is scalar(@{$manager->saves}), 1, 'セーブ追加';

    # 状態を変更
    $context->{location} = '泉';
    $context->{hp}       = 30;
    $manager->save($context, 'セーブ2');

    is scalar(@{$manager->saves}), 2, '2つ目のセーブ';

    # 最新をロード
    my ($state, $msg) = $manager->load_latest;
    is $state->{location}, '泉', '最新の場所';
    is $state->{hp},       30,  '最新のHP';

    # 古いセーブをロード
    ($state, $msg) = $manager->load(0);
    is $state->{location}, '小道', '古いセーブの場所';
    is $state->{hp},       80,   '古いセーブのHP';
};

subtest 'SaveManager - 最大数制限' => sub {
    my $manager = SaveManager->new(max_saves => 3);

    for my $i (1 .. 5) {
        $manager->save({location => "場所$i", hp => $i * 10});
    }

    is scalar(@{$manager->saves}), 3, '最大3つまで';

    my ($state, $msg) = $manager->load(0);
    is $state->{location}, '場所3', '古いセーブは削除';
};

subtest 'SaveManager - セーブ一覧' => sub {
    my $manager = SaveManager->new;

    my $list = $manager->list_saves;
    like $list, qr/セーブデータがありません/, '空の一覧';

    $manager->save({location => '森', hp => 100}, 'テスト');
    $list = $manager->list_saves;
    like $list, qr/テスト/, 'ラベルが表示';
};

done_testing;
