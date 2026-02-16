package RingiProcessor::WithManagerApproval;
use v5.36;
use parent 'RingiProcessor::Decorator';

# 部長承認を追加する包帯

sub process ($self, $ringi) {
    my $result = $self->{inner}->process($ringi);
    my $bumon  = $ringi->{bumon};

    # 承認完了の前に部長承認を挿入
    my @new_result;
    for my $line (@$result) {
        if ($line eq '承認完了') {
            push @new_result, "${bumon}部長承認: OK";
        }
        push @new_result, $line;
    }

    return \@new_result;
}

1;
