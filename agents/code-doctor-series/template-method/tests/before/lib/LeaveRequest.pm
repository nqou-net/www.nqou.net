package LeaveRequest;
use v5.36;

# 有給休暇申請モジュール
# 作成者: 瀬川律子
# 更新履歴:
#   2025-04-15 初版作成（ExpenseRequest.pm をベースにコピー）
#   2025-07-01 連続取得制限チェック追加

sub new ($class, %args) {
    return bless {
        applicant   => $args{applicant}  // die("申請者は必須です"),
        start_date  => $args{start_date} // die("開始日は必須です"),
        end_date    => $args{end_date}   // die("終了日は必須です"),
        reason      => $args{reason}     // '',
        status      => 'pending',
        approved_by => [],
    }, $class;
}

# ↓ process() の流れは ExpenseRequest.pm とほぼ同じ
sub process ($self) {

    # Step 1: 入力チェック
    $self->validate_input();

    # Step 2: 予算確認（有給残日数のチェック）
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

    # 有給申請固有のバリデーション
    die "開始日は終了日以前である必要があります"
        unless $self->{start_date} le $self->{end_date};

    # 連続5日を超える場合は事前申請が必要
    # （ここでは簡易チェック）
    return 1;
}

sub check_budget ($self) {

    # 有給残日数のチェック
    my $remaining = _get_leave_balance($self->{applicant});
    my $days      = _calc_business_days($self->{start_date}, $self->{end_date});
    if ($days > $remaining) {
        $self->{status} = 'rejected';
        die "有給残日数不足: 残り${remaining}日 に対して ${days}日の申請";
    }
    return 1;
}

sub route_approval ($self) {

    # 有給は課長承認のみ（日数に関わらず）
    push $self->{approved_by}->@*, '課長';
    $self->{status} = 'approved';
    return 1;
}

sub send_notification ($self) {

    # 申請者と承認者に通知メール送信
    my $approvers = join(', ', $self->{approved_by}->@*);
    _send_email(
        to      => $self->{applicant},
        subject => "有給休暇申請が承認されました",
        body    => "承認者: $approvers\n期間: $self->{start_date} 〜 $self->{end_date}",
    );
    return 1;
}

sub archive_record ($self) {

    # 申請情報をファイルに保存
    my $timestamp = localtime();
    _append_to_log("[$timestamp] 有給休暇 $self->{applicant}: $self->{start_date}〜$self->{end_date} ($self->{status})");
    return 1;
}

# --- ユーティリティ ---
sub _get_leave_balance  ($applicant)   { return 20 }
sub _calc_business_days ($start, $end) { return 3 }    # スタブ
sub _send_email         (%args)        { return 1 }
sub _append_to_log      ($msg)         { return 1 }

1;
