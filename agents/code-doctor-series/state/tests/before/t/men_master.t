use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use MenMaster;

subtest '正常な調理フロー' => sub {
    my $m = MenMaster->new;
    is $m->take_order('味噌ラーメン'), '注文OK: 味噌ラーメン (regular)', '注文受付';
    is $m->start_boiling, '茹で開始: 味噌ラーメン', '茹で開始';
    is $m->start_topping, '盛り付け開始: 味噌ラーメン', '盛り付け開始';
    is $m->serve, '提供完了: 味噌ラーメン（お待たせしました！）', '提供';
};

subtest '注文なしで茹でようとする' => sub {
    my $m = MenMaster->new;
    eval { $m->start_boiling };
    like $@, qr/注文来てない/, '注文前に茹でるとエラー';
};

subtest '茹でずに盛り付けようとする' => sub {
    my $m = MenMaster->new;
    $m->take_order('豚骨ラーメン');
    eval { $m->start_topping };
    like $@, qr/茹でてない/, '茹で前に盛り付けるとエラー';
};

subtest '盛り付けずに提供しようとする' => sub {
    my $m = MenMaster->new;
    $m->take_order('醤油ラーメン');
    $m->start_boiling;
    eval { $m->serve };
    like $@, qr/盛り付けてない/, '盛り付け前に提供するとエラー';
};

subtest 'エラー中の操作制限' => sub {
    my $m = MenMaster->new;
    $m->take_order('塩ラーメン');
    $m->set_error('麺が切れた');
    eval { $m->start_boiling };
    like $@, qr/エラー中/, 'エラー中に茹でられない';
};

subtest 'リセットで全フラグクリア' => sub {
    my $m = MenMaster->new;
    $m->take_order('味噌ラーメン');
    $m->start_boiling;
    $m->reset;
    is $m->status, 'ready=0, boiling=0, topping=0, error=0, served=0', 'リセット後は全フラグ0';
};

# === ここからが問題のテスト ===
# 後輩が見つけたバグ: フラグの不整合が起きるケース

subtest 'BUG: 提供済みからの再注文（フラグリセット漏れ）' => sub {
    my $m = MenMaster->new;
    $m->take_order('味噌ラーメン');
    $m->start_boiling;
    $m->start_topping;
    $m->serve;

    # 提供済みから再注文 → is_served=1 のままリセットされる「はず」だが……
    $m->take_order('醤油ラーメン');

    # is_served が 0 に戻っているか？
    # 実は take_order 内の「リセット的な何か」で is_served = 0 になるが、
    # 他のフラグとの整合性は保証されていない！
    like $m->status, qr/served=0/, '提供済みフラグはリセットされる（が他は？）';
};

done_testing;
