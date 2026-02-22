package DeployTool;
use v5.36;

sub new ($class) {
    bless { log => [], state => { app => 'old_version', service => 'running', db => 'normal' } }, $class;
}

sub deploy ($self) {
    # 職人の魂がこもった長大なサブルーチン
    eval {
        $self->_stop_service();
        $self->_backup_db();
        $self->_update_app();
        $self->_start_service();
    };
    if ($@) {
        # エラーが起きたらどうする？
        # 「頼む、途中でコケないでくれ」と祈るしかない。
        push $self->{log}->@*, "ERROR: $@";
        die "Deploy failed! Manual rollback required.\n";
    }
}

sub _stop_service ($self) {
    push $self->{log}->@*, "Stopping service...";
    $self->{state}{service} = 'stopped';
}

sub _backup_db ($self) {
    push $self->{log}->@*, "Backing up DB...";
    $self->{state}{db} = 'backed_up';
}

sub _update_app ($self) {
    push $self->{log}->@*, "Updating application...";
    # わざとエラーを起こすテスト用フラグ
    die "Network error during update" if $self->{fail_update};
    $self->{state}{app} = 'new_version';
}

sub _start_service ($self) {
    push $self->{log}->@*, "Starting service...";
    $self->{state}{service} = 'running';
}

1;
