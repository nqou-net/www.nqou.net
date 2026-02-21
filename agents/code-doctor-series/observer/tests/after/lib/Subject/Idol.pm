package Subject::Idol;
use v5.36;
use utf8;
use experimental 'signatures';

# ドクターが提示した、健全なPush型の Subject（配信元）
sub new ($class, $name) {
    bless {
        name      => $name,
        status    => 'normal',
        observers => [],         # サブスクライバー（ファン）のリスト
    }, $class;
}

# ファンをリストに登録する（Webhookの登録など）
sub attach ($self, $observer) {
    push $self->{observers}->@*, $observer;
}

# ファンをリストから外す（推し活引退）
sub detach ($self, $observer) {
    $self->{observers} = [grep { $_ ne $observer } $self->{observers}->@*];
}

# 状態が変わった時にだけ実行される（管理者側の操作）
sub set_status ($self, $new_status) {
    $self->{status} = $new_status;

    # 状態が変わったことを、自ら全員に通知する（Push型）
    $self->notify();
}

sub get_status ($self) {
    return $self->{status};
}

sub get_name ($self) {
    return $self->{name};
}

# リストに登録されたファン全てに状態を通知する
sub notify ($self) {
    foreach my $observer ($self->{observers}->@*) {
        $observer->update($self);
    }
}

1;
