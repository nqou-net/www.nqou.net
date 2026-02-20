use v5.36;
use Test::More;
use lib 'lib';

use ExpenseRequest;
use LeaveRequest;
use EquipmentRequest;
use CondolenceRequest;

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
        applicant => '田中太郎',
        amount    => 30_000,
        category  => '交際費',
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

# --- 慶弔見舞金申請テスト（新規追加の実証） ---
subtest 'condolence request - with hook method' => sub {
    my $req = CondolenceRequest->new(
        applicant  => '田中太郎',
        event_type => '結婚',
        amount     => 30_000,
    );
    my $status = $req->process();
    is($status, 'approved', '慶弔見舞金申請は承認される');
    is_deeply($req->{approved_by}, ['課長', '部長', '人事部長'], '慶弔は3段階承認');
    ok($req->{manager_comment_required}, 'フックメソッドにより上長コメント必須');
};

subtest 'condolence request - hook method differentiation' => sub {

    # フックメソッドの効果を確認:
    # 経費申請ではrequires_manager_comment()がfalse
    # 慶弔申請ではrequires_manager_comment()がtrue
    my $expense = ExpenseRequest->new(
        applicant => '田中太郎',
        amount    => 5000,
        category  => '交通費',
    );
    my $condolence = CondolenceRequest->new(
        applicant  => '田中太郎',
        event_type => '結婚',
        amount     => 30_000,
    );

    ok(!$expense->requires_manager_comment(),   '経費申請は上長コメント不要');
    ok($condolence->requires_manager_comment(), '慶弔申請は上長コメント必要');
};

# --- Template Method の効果を実証 ---
subtest 'template method pattern benefit' => sub {
    note("--- Template Method パターンの効果 ---");
    note("1. 基底クラス AbstractRequest が処理フローの骨格を定義");
    note("2. 各サブクラスは差分（validate_input, route_approval）のみ実装");
    note("3. 新しい申請種別の追加は新サブクラスの作成のみ — 既存コードは一切変更なし");
    note("4. フックメソッド（requires_manager_comment）で柔軟なカスタマイズが可能");

    # 全サブクラスが AbstractRequest を継承していることを確認
    for my $class (qw(ExpenseRequest LeaveRequest EquipmentRequest CondolenceRequest)) {
        isa_ok(
            $class->new(
                applicant => 'test',
                ($class eq 'ExpenseRequest'    ? (amount     => 100,          category   => '交通費')        : ()),
                ($class eq 'LeaveRequest'      ? (start_date => '2025-01-01', end_date   => '2025-01-02') : ()),
                ($class eq 'EquipmentRequest'  ? (item_name  => 'test',       unit_price => 100)          : ()),
                ($class eq 'CondolenceRequest' ? (event_type => '結婚',         amount     => 100)          : ()),
            ),
            'AbstractRequest',
            "$class は AbstractRequest を継承"
        );
    }
};

done_testing;
