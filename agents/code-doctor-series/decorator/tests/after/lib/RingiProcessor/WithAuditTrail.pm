package RingiProcessor::WithAuditTrail;
use v5.36;
use parent 'RingiProcessor::Decorator';

# 監査証跡を追加する包帯（来月追加予定だった新機能）

sub process ($self, $ringi) {
    my $result   = $self->{inner}->process($ringi);
    my $kian_sha = $ringi->{kian_sha};
    my $kingaku  = $ringi->{kingaku};

    my $audit_entry = sprintf("[AUDIT] %s: %sさんの稟議（%d円）- 承認プロセス記録", $self->_now(), $kian_sha, $kingaku);

    # 承認完了の前に監査証跡を挿入
    my @new_result;
    for my $line (@$result) {
        if ($line eq '承認完了') {
            push @new_result, $audit_entry;
        }
        push @new_result, $line;
    }

    return \@new_result;
}

sub _now ($self) {
    return "2026-02-17T10:00:00";
}

1;
