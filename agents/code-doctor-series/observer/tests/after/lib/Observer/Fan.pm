package Observer::Fan;
use v5.36;
use utf8;
use experimental 'signatures';

# 通知を受け取る側（Observer）。
# Subject（アイドル側）から `update` メソッドが呼ばれることを期待している。
sub new ($class, $platform, $username) {
    bless {
        platform      => $platform,
        username      => $username,
        notifications => [],
    }, $class;
}

# Subject側から状態変化時にPushで叩かれる（Webhookハンドラのようなもの）
sub update ($self, $subject) {
    my $msg = sprintf("[%s/%s] %s の状態が %s になりました！全裸待機します！", $self->{platform}, $self->{username}, $subject->get_name(), $subject->get_status());
    push $self->{notifications}->@*, $msg;
}

sub get_notifications ($self) {
    return $self->{notifications};
}

1;
