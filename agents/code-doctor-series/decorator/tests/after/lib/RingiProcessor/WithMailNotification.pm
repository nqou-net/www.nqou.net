package RingiProcessor::WithMailNotification;
use v5.36;
use parent 'RingiProcessor::Decorator';

# メール通知を追加する包帯

my %MAIL_MAP = (
    '総務' => 'soumu@example.com',
    '営業' => 'eigyo@example.com',
    '開発' => 'kaihatsu@example.com',
);

sub process ($self, $ringi) {
    my $result  = $self->{inner}->process($ringi);
    my $bumon   = $ringi->{bumon};
    my $kingaku = $ringi->{kingaku};

    my $mail_to = $MAIL_MAP{$bumon} // "${bumon}\@example.com";

    my @new_result;
    for my $line (@$result) {
        if ($line eq '承認完了') {
            push @new_result, "メール通知: $mail_to";
            if ($kingaku >= 1_000_000) {
                push @new_result, "メール通知(CC): keiri\@example.com";
            }
        }
        push @new_result, $line;
    }

    return \@new_result;
}

1;
