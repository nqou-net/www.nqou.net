package Article;
use v5.36;

sub new ($class, %args) {
    bless { %args }, $class;
}

sub publish ($self) {
    say "Publishing article: " . $self->{title};

    # Slack Notification
    # 元々はここだけだったのに...
    if ($self->{enable_slack}) {
        say "[Slack] Sending to #general: New article published!";
    }

    # Discord Notification
    # 3ヶ月前に追加された
    if ($self->{enable_discord}) {
        say "[Discord] Sending to guild: New article published!";
    }

    # Email Notification
    # 先週追加された...
    if ($self->{enable_email}) {
        say "[Email] Sending to subscribers: New article published!";
    }

    # LINE Notification
    # 昨日言われて急いで追加した
    if ($self->{enable_line}) {
        say "[LINE] Sending to official account: New article published!";
    }
}

1;
