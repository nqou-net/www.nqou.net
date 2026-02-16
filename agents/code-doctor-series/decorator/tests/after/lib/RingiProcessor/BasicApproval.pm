package RingiProcessor::BasicApproval;
use v5.36;
use parent 'RingiProcessor';

# コア処理: 稟議の基本承認フローのみ（裸の傷口）

sub process ($self, $ringi) {
    my $kian_sha = $ringi->{kian_sha};
    my $kingaku  = $ringi->{kingaku};

    return ["承認開始: ${kian_sha}さんの稟議（${kingaku}円）", "係長承認: OK", "承認完了",];
}

1;
