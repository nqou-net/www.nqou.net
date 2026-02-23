package AlertMonitor;
use v5.36;

# 黒崎のアラート監視スクリプト（18年の歴史）
# ※ 新しい種別を追加する時はここにelsifを足すこと
# ※ 順番を変えると壊れるので注意（2019年に学んだ）

sub new ($class) {
    return bless {
        log => [],
    }, $class;
}

sub check_alert ($self, $alert) {
    my $type     = $alert->{type}     // 'unknown';
    my $severity = $alert->{severity} // 0;
    my $source   = $alert->{source}   // 'unknown';
    my $message  = $alert->{message}  // '';

    # --- ここから地獄の条件分岐 ---

    if ($type eq 'cpu' && $severity >= 90) {
        # CPU クリティカル → 即座にPagerDuty
        $self->_notify_pagerduty($alert);
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty');
    }
    elsif ($type eq 'cpu' && $severity >= 70) {
        # CPU 警告 → Slackの#alertsチャンネル
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    elsif ($type eq 'cpu' && $severity >= 50) {
        # CPU 注意 → ログだけ
        $self->_log_alert($alert, 'INFO', 'log_only');
    }
    elsif ($type eq 'memory' && $severity >= 95) {
        # メモリ クリティカル → PagerDuty + Slack
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty+slack');
    }
    elsif ($type eq 'memory' && $severity >= 80) {
        # メモリ 警告 → Slack
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    elsif ($type eq 'memory' && $severity >= 60) {
        # メモリ 注意 → ログだけ
        $self->_log_alert($alert, 'INFO', 'log_only');
    }
    elsif ($type eq 'disk' && $severity >= 90) {
        # ディスク クリティカル
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#infra');
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty+slack');
    }
    elsif ($type eq 'disk' && $severity >= 70) {
        $self->_notify_slack($alert, '#infra');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    elsif ($type eq 'network' && $severity >= 80) {
        # ネットワーク障害 → 即PagerDuty（2021年の障害で追加）
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty+slack');
    }
    elsif ($type eq 'network' && $severity >= 50) {
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    elsif ($type eq 'process' && $message =~ /OOM/) {
        # OOMKiller発動 → 最優先（2023年に追加）
        $self->_notify_pagerduty($alert);
        $self->_notify_slack($alert, '#alerts');
        $self->_notify_slack($alert, '#infra');
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty+slack_multi');
    }
    elsif ($type eq 'process' && $severity >= 70) {
        $self->_notify_slack($alert, '#alerts');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    elsif ($type eq 'ssl_cert' && $severity >= 80) {
        # SSL証明書期限切れ間近（2024年に慌てて追加）
        $self->_notify_slack($alert, '#security');
        $self->_notify_pagerduty($alert);
        $self->_log_alert($alert, 'CRITICAL', 'pagerduty+slack');
    }
    elsif ($type eq 'ssl_cert' && $severity >= 50) {
        $self->_notify_slack($alert, '#security');
        $self->_log_alert($alert, 'WARNING', 'slack');
    }
    # TODO: ここに新しい種別を追加する（もう無理かもしれない）
    else {
        # どれにも該当しない → とりあえずログ
        $self->_log_alert($alert, 'UNKNOWN', 'log_only');
    }
}

# --- 通知メソッド ---

sub _notify_pagerduty ($self, $alert) {
    push $self->{log}->@*, "PAGERDUTY: [$alert->{type}] $alert->{message}";
}

sub _notify_slack ($self, $alert, $channel) {
    push $self->{log}->@*, "SLACK($channel): [$alert->{type}] $alert->{message}";
}

sub _log_alert ($self, $alert, $level, $dest) {
    push $self->{log}->@*, "LOG[$level]($dest): [$alert->{type}] severity=$alert->{severity}";
}

sub get_log ($self) {
    return $self->{log}->@*;
}

1;
