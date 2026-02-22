use v5.36;
use Test2::V0;
use lib 'lib';
use Server;
use DeployJob;
use Command::StopService;
use Command::BackupDB;
use Command::UpdateApp;
use Command::StartService;

subtest "Successful deploy" => sub {
    my $server = Server->new;
    my $job    = DeployJob->new;

    $job->add_command(Command::StopService->new($server));
    $job->add_command(Command::BackupDB->new($server));
    $job->add_command(Command::UpdateApp->new($server));
    $job->add_command(Command::StartService->new($server));

    $job->execute();

    is $server->{state}{app},     'new_version', "App is updated";
    is $server->{state}{service}, 'running',     "Service is running";
    is $server->{state}{db},      'backed_up',   "DB is backed up";
};

subtest "Failed deploy securely rolls back to initial state" => sub {
    my $server = Server->new;
    my $job    = DeployJob->new;

    $job->add_command(Command::StopService->new($server));
    $job->add_command(Command::BackupDB->new($server));

    # fail=1 を渡してわざと失敗させる
    $job->add_command(Command::UpdateApp->new($server, 1));
    $job->add_command(Command::StartService->new($server));

    my $err = dies { $job->execute() };
    like $err, qr/Deploy failed, rolled back securely/, "Error is caught and rollback is executed";

    # ロールバックのおかげで、状態は完全に元通りになっている！
    is $server->{state}{app},     'old_version', "App is reverted safely";
    is $server->{state}{service}, 'running',     "Service is running again (rolled back)";
    is $server->{state}{db},      'normal',      "DB is normal (restored)";

    # ログを見て逆順にUndoが呼ばれたことを確認
    my $logs = $server->{log};

    # 実行ログ:
    # 0: Stopping service...
    # 1: Backing up DB...
    # 2: Updating application... (dies)
    # 3: UNDO: Restoring DB...
    # 4: UNDO: Starting service...
    is $logs->[-2], "UNDO: Restoring DB...",     "DB restored first (LIFO order)";
    is $logs->[-1], "UNDO: Starting service...", "Service started last";
};

done_testing;
