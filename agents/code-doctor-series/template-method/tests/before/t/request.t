use v5.36;
use Test::More;
use lib 'lib';

use ExpenseRequest;
use LeaveRequest;
use EquipmentRequest;

# --- 経費精算申請テスト ---
subtest 'expense request - basic flow' => sub {
    my $req = ExpenseRequest->new(
        applicant   => '田中太郎',
        amount      => 5_000,
        category    => '交通費',
        description => '出張時のタクシー代',
    );
    my $status = $req->process();
    is($status, 'approved', '5,000円の経費精算は承認される');
    is_deeply($req->{approved_by}, ['課長'], '1万円未満は課長のみ');
};

subtest 'expense request - large amount' => sub {
    my $req = ExpenseRequest->new(
        applicant   => '田中太郎',
        amount      => 30_000,
        category    => '交際費',
        description => '取引先との会食',
    );
    my $status = $req->process();
    is($status, 'approved', '30,000円の経費精算は承認される');
    is_deeply($req->{approved_by}, ['課長', '部長'], '1万円以上は課長→部長');
};

subtest 'expense request - invalid category' => sub {
    my $req = ExpenseRequest->new(
        applicant => '田中太郎',
        amount    => 1_000,
        category  => '娯楽費',
    );
    eval { $req->process() };
    like($@, qr/無効な経費カテゴリ/, '無効なカテゴリはエラー');
};

# --- 有給休暇申請テスト ---
subtest 'leave request - basic flow' => sub {
    my $req = LeaveRequest->new(
        applicant  => '田中太郎',
        start_date => '2025-12-01',
        end_date   => '2025-12-03',
        reason     => '家庭の事情',
    );
    my $status = $req->process();
    is($status, 'approved', '有給休暇申請は承認される');
    is_deeply($req->{approved_by}, ['課長'], '有給は常に課長のみ');
};

# --- 備品購入申請テスト ---
subtest 'equipment request - small purchase' => sub {
    my $req = EquipmentRequest->new(
        applicant  => '田中太郎',
        item_name  => 'USBメモリ',
        quantity   => 3,
        unit_price => 2_000,
    );
    my $status = $req->process();
    is($status, 'approved', '備品購入申請は承認される');
    is_deeply($req->{approved_by}, ['課長'], '5万円未満は課長のみ');
};

subtest 'equipment request - large purchase' => sub {
    my $req = EquipmentRequest->new(
        applicant  => '田中太郎',
        item_name  => 'モニター',
        quantity   => 2,
        unit_price => 40_000,
    );
    my $status = $req->process();
    is($status, 'approved', '高額備品も承認される');
    is_deeply($req->{approved_by}, ['課長', '部長', '総務部長'], '5万円以上は3段階承認');
};

# --- コピペ増殖の問題点を示すテスト ---
subtest 'code duplication problem' => sub {
    note("--- コピペ増殖の問題 ---");
    note("ExpenseRequest::process, LeaveRequest::process, EquipmentRequest::process");
    note("3つのモジュールの process() はほぼ同一のフロー:");
    note("  validate_input -> check_budget -> route_approval -> send_notification -> archive_record");
    note("差異は validate_input() の内容と route_approval() の承認ルートのみ");
    note("");
    note("問題: 新しい申請種別を追加するたびに、このフロー全体をコピペする必要がある");
    note("      → 修正漏れ、テストの重複、保守コストの増大");

    # 構造的に同じメソッドが存在することを確認
    for my $class (qw(ExpenseRequest LeaveRequest EquipmentRequest)) {
        for my $method (qw(process validate_input check_budget route_approval send_notification archive_record)) {
            ok($class->can($method), "$class has $method method");
        }
    }
};

done_testing;
