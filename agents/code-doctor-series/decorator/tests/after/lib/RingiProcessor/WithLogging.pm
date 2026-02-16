package RingiProcessor::WithLogging;
use v5.36;
use parent 'RingiProcessor::Decorator';

# ログ記録を追加する包帯

sub process ($self, $ringi) {
    my $result   = $self->{inner}->process($ringi);
    my $bumon    = $ringi->{bumon};
    my $kian_sha = $ringi->{kian_sha};
    my $kingaku  = $ringi->{kingaku};

    my $log_entry = sprintf("[LOG] %s: %s部 %sさん %d円 - 承認完了", $self->_now(), $bumon, $kian_sha, $kingaku);

    # 承認完了の前にログ記録を挿入
    my @new_result;
    for my $line (@$result) {
        if ($line eq '承認完了') {
            push @new_result, $log_entry;
        }
        push @new_result, $line;
    }

    return \@new_result;
}

sub _now ($self) {
    return "2026-02-17T10:00:00";
}

1;
