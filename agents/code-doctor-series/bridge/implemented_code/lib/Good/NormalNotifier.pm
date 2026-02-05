package Good::NormalNotifier;
use v5.36;
use parent 'Good::Notifier';

# RefinedAbstraction
sub format_message {
    my ($self, $message) = @_;

    # 機能拡張: 通常メッセージ
    return "[Info] " . $message;
}

1;
