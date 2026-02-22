use v5.36;
use Test2::V0;
use lib 'lib';
use DeployTool;

subtest "Successful deploy" => sub {
    my $tool = DeployTool->new;
    $tool->deploy();

    is $tool->{state}{service}, 'running',     "Service is running";
    is $tool->{state}{app},     'new_version', "App is updated";
    is $tool->{state}{db},      'backed_up',   "DB is backed up";
};

subtest "Failed deploy leaves system in broken state" => sub {
    my $tool = DeployTool->new;
    $tool->{fail_update} = 1;    # 途中で失敗させる

    my $err = dies { $tool->deploy() };
    like $err, qr/Deploy failed! Manual rollback required/, "Catches deploy error";

    # 途中で止まってしまったため、サービスは停止したまま、DBはバックアップ状態のまま
    is $tool->{state}{service}, 'stopped',     "Service is left stopped (broken state)";
    is $tool->{state}{app},     'old_version', "App is NOT updated (since it failed)";

    # Undo（元に戻す手段）が存在しないため、オペレータの手作業が必要になる悲劇
};

done_testing;
