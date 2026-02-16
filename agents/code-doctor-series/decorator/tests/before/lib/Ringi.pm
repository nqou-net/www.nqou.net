package Ringi;
use v5.36;

# 稟議書承認フロー処理
# FIXME: 監査ログ機能を追加したいけど、もうどこに入れたらいいか分からない（by ヨリコ）
# TODO: 来月までに $needs_audit_log を追加する……気が重い

sub process_ringi ($ringi) {
    my $kingaku       = $ringi->{kingaku};        # 金額
    my $bumon         = $ringi->{bumon};           # 部門
    my $kian_sha      = $ringi->{kian_sha};        # 起案者
    my $kengen        = $ringi->{kengen} // '';     # 権限

    # フラグ変数（付箋のつもりで追加していったら増えすぎた）
    my $needs_buchou_hanko  = 0;  # 部長の判子が必要か
    my $needs_yakuin_hanko  = 0;  # 役員の判子が必要か
    my $needs_mail          = 0;  # メール通知が必要か
    my $needs_log           = 0;  # ログ記録が必要か

    my @result = ();

    # ---- 金額による判定 ----
    if ($kingaku < 100_000) {
        # 10万未満: 係長決裁のみ
        $needs_buchou_hanko = 0;
        $needs_yakuin_hanko = 0;
        $needs_mail         = 0;
        $needs_log          = 1;
    }
    elsif ($kingaku < 500_000) {
        # 10万以上50万未満: 部長決裁
        $needs_buchou_hanko = 1;
        $needs_yakuin_hanko = 0;
        $needs_mail         = 1;
        $needs_log          = 1;
    }
    elsif ($kingaku < 1_000_000) {
        # 50万以上100万未満: 部長＋役員決裁
        $needs_buchou_hanko = 1;
        $needs_yakuin_hanko = 1;
        $needs_mail         = 1;
        $needs_log          = 1;
    }
    else {
        # 100万以上: 全承認ステップ
        $needs_buchou_hanko = 1;
        $needs_yakuin_hanko = 1;
        $needs_mail         = 1;
        $needs_log          = 1;
    }

    # ---- 基本承認処理 ----
    push @result, "承認開始: $kian_sha さんの稟議（${kingaku}円）";
    push @result, "係長承認: OK";

    # ---- 部長判子 ----
    if ($needs_buchou_hanko) {
        if ($bumon eq '総務') {
            push @result, "総務部長承認: OK";
        }
        elsif ($bumon eq '営業') {
            push @result, "営業部長承認: OK";
        }
        elsif ($bumon eq '開発') {
            push @result, "開発部長承認: OK";
        }
        else {
            push @result, "${bumon}部長承認: OK";
        }
    }

    # ---- 役員判子 ----
    if ($needs_yakuin_hanko) {
        push @result, "役員承認: OK";
        # 役員承認の時はメール通知も必ずする（はず……たぶん）
        $needs_mail = 1;
    }

    # ---- メール通知 ----
    if ($needs_mail) {
        if ($bumon eq '総務') {
            push @result, "メール通知: soumu\@example.com";
        }
        elsif ($bumon eq '営業') {
            push @result, "メール通知: eigyo\@example.com";
        }
        elsif ($bumon eq '開発') {
            push @result, "メール通知: kaihatsu\@example.com";
        }
        else {
            push @result, "メール通知: ${bumon}\@example.com";
        }

        # 100万以上は経理にもCC（これいつ追加したっけ……）
        if ($kingaku >= 1_000_000) {
            push @result, "メール通知(CC): keiri\@example.com";
        }
    }

    # ---- ログ記録 ----
    if ($needs_log) {
        my $log_entry = sprintf("[LOG] %s: %s部 %sさん %d円 - 承認完了",
            _now(), $bumon, $kian_sha, $kingaku);
        push @result, $log_entry;
    }

    push @result, "承認完了";

    return \@result;
}

# 現在日時（テスト用に固定可能にしたかったけど、まあいいか）
sub _now {
    return "2026-02-17T10:00:00";
}

1;
