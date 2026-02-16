package RingiProcessor::WithExecutiveApproval;
use v5.36;
use parent 'RingiProcessor::Decorator';

# 役員承認を追加する包帯

sub process ($self, $ringi) {
    my $result = $self->{inner}->process($ringi);

    # 承認完了の前に役員承認を挿入
    my @new_result;
    for my $line (@$result) {
        if ($line eq '承認完了') {
            push @new_result, "役員承認: OK";
        }
        push @new_result, $line;
    }

    return \@new_result;
}

1;
