package DeployJob;
use v5.36;

sub new ($class) {
    bless {commands => [], history => []}, $class;
}

sub add_command ($self, $cmd) {
    push $self->{commands}->@*, $cmd;
}

sub execute ($self) {
    eval {
        for my $cmd ($self->{commands}->@*) {
            $cmd->execute();

            # 成功したコマンドだけを履歴（スタック）に積む
            push $self->{history}->@*, $cmd;
        }
    };
    if ($@) {
        my $err = $@;

        # エラー発生時は、履歴を逆順に取り出しながら undo を呼ぶ（安全なロールバック）
        $self->undo();
        die "Deploy failed, rolled back securely. Reason: $err";
    }
}

sub undo ($self) {

    # 履歴スタックから後入れ先出し(LIFO)で取り出す
    while (my $cmd = pop $self->{history}->@*) {
        $cmd->undo();
    }
}

1;
