package Notification::Slack;
use v5.36;
use parent 'Role::Observer';

sub new ($class) { bless {}, $class }

sub update ($self, $subject) {

    # 実際にはここにSlack APIへの投稿処理が入る
    say "[Slack] Notification: " . $subject->title;
}

1;
