use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MenMaster;

subtest '正常な調理フロー' => sub {
    my $m = MenMaster->new;
    is $m->status, 'WaitingOrder', '初期状態は注文待ち';
    is $m->take_order('味噌ラーメン'), '注文OK: 味噌ラーメン (regular)', '注文受付';
    is $m->status, 'Preparing', '仕込み状態に遷移';
    is $m->start_boiling, '茹で開始: 味噌ラーメン', '茹で開始';
    is $m->status, 'Boiling', '茹で中状態に遷移';
    is $m->start_topping, '盛り付け開始: 味噌ラーメン', '盛り付け開始';
    is $m->status, 'Topping', '盛り付け中状態に遷移';
    is $m->serve, '提供完了: 味噌ラーメン（お待たせしました！）', '提供';
    is $m->status, 'Completed', '完了状態に遷移';
};

subtest '麺の種類指定' => sub {
    my $m = MenMaster->new;
    is $m->take_order('味噌ラーメン', 'hard'), '注文OK: 味噌ラーメン (hard)', '硬めで注文';
};

subtest '無効な遷移: 注文待ちから茹で開始' => sub {
    my $m = MenMaster->new;
    eval { $m->start_boiling };
    like $@, qr/WaitingOrder状態では「茹で開始」はできません/, '注文前に茹でるとエラー';
};

subtest '無効な遷移: 仕込みから盛り付け' => sub {
    my $m = MenMaster->new;
    $m->take_order('豚骨ラーメン');
    eval { $m->start_topping };
    like $@, qr/Preparing状態では「盛り付け」はできません/, '茹で前に盛り付けるとエラー';
};

subtest '無効な遷移: 仕込みから提供' => sub {
    my $m = MenMaster->new;
    $m->take_order('醤油ラーメン');
    eval { $m->serve };
    like $@, qr/Preparing状態では「提供」はできません/, '仕込みから直接提供はエラー';
};

subtest '無効な遷移: 茹で中から提供（盛り付けスキップ）' => sub {
    my $m = MenMaster->new;
    $m->take_order('醤油ラーメン');
    $m->start_boiling;
    eval { $m->serve };
    like $@, qr/Boiling状態では「提供」はできません/, '茹で中から直接提供はエラー';
};

subtest '無効な遷移: 完了状態から茹で開始' => sub {
    my $m = MenMaster->new;
    $m->take_order('塩ラーメン');
    $m->start_boiling;
    $m->start_topping;
    $m->serve;
    eval { $m->start_boiling };
    like $@, qr/Completed状態では「茹で開始」はできません/, '完了から茹でるのはエラー';
};

subtest '連続注文: 完了後に次の注文' => sub {
    my $m = MenMaster->new;
    $m->take_order('味噌ラーメン');
    $m->start_boiling;
    $m->start_topping;
    $m->serve;
    is $m->status, 'Completed', '1杯目完了';

    is $m->take_order('醤油ラーメン'), '注文OK: 醤油ラーメン (regular)', '2杯目の注文';
    is $m->status, 'Preparing', '仕込み状態に遷移';
    is $m->start_boiling, '茹で開始: 醤油ラーメン', '2杯目茹で開始';
};

subtest 'リセット' => sub {
    my $m = MenMaster->new;
    $m->take_order('味噌ラーメン');
    $m->start_boiling;
    is $m->reset, 'リセット完了（まっさらだ！）', 'リセット';
    is $m->status, 'WaitingOrder', 'リセット後は注文待ち';
};

done_testing;
