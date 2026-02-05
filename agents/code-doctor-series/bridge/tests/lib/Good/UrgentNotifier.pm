package Good::UrgentNotifier;
use v5.36;
use parent 'Good::Notifier';

# RefinedAbstraction
sub format_message {
    my ($self, $message) = @_;

    # 機能拡張: 急ぎのメッセージは強調する
    return "[URGENT] " . uc($message) . " !!!";
}

1;
