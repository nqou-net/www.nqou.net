package ExpenseRequest;
use v5.36;

# 経費精算申請モジュール
# 作成者: 瀬川律子
# 更新履歴:
#   2025-04-01 初版作成
#   2025-06-15 消費税計算ロジック追加
#   2025-09-01 部長承認ルート追加（1万円以上の場合）

sub new ($class, %args) {
    return bless {
        applicant   => $args{applicant}   // die("申請者は必須です"),
        amount      => $args{amount}      // die("金額は必須です"),
        category    => $args{category}    // die("経費カテゴリは必須です"),
        description => $args{description} // '',
        status      => 'pending',
        approved_by => [],
    }, $class;
}

sub process ($self) {
    # Step 1: 入力チェック
    $self->validate_input();

    # Step 2: 予算確認
    $self->check_budget();

    # Step 3: 承認ルート
    $self->route_approval();

    # Step 4: 通知
    $self->send_notification();

    # Step 5: 記録保存
    $self->archive_record();

    return $self->{status};
}

sub validate_input ($self) {
    die "金額は正の数である必要があります"
        unless $self->{amount} > 0;
    my @valid_categories = qw(交通費 宿泊費 交際費 消耗品費 通信費);
    die "無効な経費カテゴリ: $self->{category}"
        unless grep { $_ eq $self->{category} } @valid_categories;
    return 1;
}

sub check_budget ($self) {
    # 部署予算の残高チェック（簡易版）
    my $remaining = _get_department_budget($self->{applicant});
    if ($self->{amount} > $remaining) {
        $self->{status} = 'rejected';
        die "予算超過: 残高 ${remaining}円 に対して ${\ $self->{amount}}円の申請";
    }
    return 1;
}

sub route_approval ($self) {
    # 1万円未満: 課長承認のみ
    # 1万円以上: 課長 → 部長の二段階承認
    push $self->{approved_by}->@*, '課長';
    if ($self->{amount} >= 10_000) {
        push $self->{approved_by}->@*, '部長';
    }
    $self->{status} = 'approved';
    return 1;
}

sub send_notification ($self) {
    # 申請者と承認者に通知メール送信
    my $approvers = join(', ', $self->{approved_by}->@*);
    _send_email(
        to      => $self->{applicant},
        subject => "経費精算申請が承認されました",
        body    => "承認者: $approvers\n金額: $self->{amount}円",
    );
    return 1;
}

sub archive_record ($self) {
    # 申請情報をファイルに保存
    my $timestamp = localtime();
    _append_to_log("[$timestamp] 経費精算 $self->{applicant}: $self->{amount}円 ($self->{status})");
    return 1;
}

# --- ユーティリティ（本番ではDB/APIを使う想定） ---
sub _get_department_budget ($applicant) { return 500_000 }
sub _send_email (%args) { return 1 }  # スタブ
sub _append_to_log ($msg) { return 1 } # スタブ

1;
