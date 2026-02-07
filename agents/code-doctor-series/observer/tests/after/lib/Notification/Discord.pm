package Notification::Discord;
use v5.36;
use parent 'Role::Observer';

sub new ($class) { bless {}, $class }

sub update ($self, $subject) {

    # 実際にはここにDiscord WebHookへの投稿処理が入る
    say "[Discord] Message sent: " . $subject->title;
}

1;
