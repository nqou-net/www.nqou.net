package RingiProcessor::Factory;
use v5.36;

use RingiProcessor::BasicApproval;
use RingiProcessor::WithManagerApproval;
use RingiProcessor::WithExecutiveApproval;
use RingiProcessor::WithLogging;
use RingiProcessor::WithMailNotification;
use RingiProcessor::WithAuditTrail;

# 金額に応じて必要な Decorator を組み立てるファクトリ
# 紙の付箋を貼るように、必要な包帯だけを巻く

sub build_processor ($class, $kingaku) {

    # コア処理（裸の傷口）
    my $processor = RingiProcessor::BasicApproval->new();

    # ログ記録は常に巻く
    $processor = RingiProcessor::WithLogging->new(inner => $processor);

    if ($kingaku >= 100_000) {

        # 10万以上: 部長承認 + メール通知
        $processor = RingiProcessor::WithManagerApproval->new(inner => $processor);
        $processor = RingiProcessor::WithMailNotification->new(inner => $processor);
    }

    if ($kingaku >= 500_000) {

        # 50万以上: 役員承認も追加
        $processor = RingiProcessor::WithExecutiveApproval->new(inner => $processor);
    }

    if ($kingaku >= 1_000_000) {

        # 100万以上: 監査証跡も追加
        $processor = RingiProcessor::WithAuditTrail->new(inner => $processor);
    }

    return $processor;
}

1;
