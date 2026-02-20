package EquipmentRequest;
use v5.36;

# 備品購入申請モジュール
# 作成者: 瀬川律子
# 更新履歴:
#   2025-05-01 初版作成（ExpenseRequest.pm をベースにコピー）

sub new ($class, %args) {
    return bless {
        applicant   => $args{applicant}  // die("申請者は必須です"),
        item_name   => $args{item_name}  // die("品名は必須です"),
        quantity    => $args{quantity}   // 1,
        unit_price  => $args{unit_price} // die("単価は必須です"),
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
    die "数量は正の整数である必要があります"
        unless $self->{quantity} > 0 && $self->{quantity} == int($self->{quantity});
    die "単価は正の数である必要があります"
        unless $self->{unit_price} > 0;
    return 1;
}

sub check_budget ($self) {
    my $total     = $self->{quantity} * $self->{unit_price};
    my $remaining = _get_department_budget($self->{applicant});
    if ($total > $remaining) {
        $self->{status} = 'rejected';
        die "予算超過: 残高 ${remaining}円 に対して ${total}円の申請";
    }
    return 1;
}

sub route_approval ($self) {
    my $total = $self->{quantity} * $self->{unit_price};

    # 5万円未満: 課長のみ
    # 5万円以上: 課長 → 部長 → 総務部長
    push $self->{approved_by}->@*, '課長';
    if ($total >= 50_000) {
        push $self->{approved_by}->@*, '部長';
        push $self->{approved_by}->@*, '総務部長';
    }
    $self->{status} = 'approved';
    return 1;
}

sub send_notification ($self) {
    my $approvers = join(', ', $self->{approved_by}->@*);
    my $total     = $self->{quantity} * $self->{unit_price};
    _send_email(
        to      => $self->{applicant},
        subject => "備品購入申請が承認されました",
        body    => "承認者: $approvers\n品名: $self->{item_name}\n金額: ${total}円",
    );
    return 1;
}

sub archive_record ($self) {
    my $timestamp = localtime();
    my $total     = $self->{quantity} * $self->{unit_price};
    _append_to_log("[$timestamp] 備品購入 $self->{applicant}: $self->{item_name} x$self->{quantity} ${total}円 ($self->{status})");
    return 1;
}

# --- ユーティリティ ---
sub _get_department_budget ($applicant) { return 500_000 }
sub _send_email            (%args)      { return 1 }
sub _append_to_log         ($msg)       { return 1 }

1;
