use v5.36;
use Test::More;
use lib 'lib';
use AlertHandler;
use AlertHandler::CpuAlert;
use AlertHandler::MemoryAlert;
use AlertHandler::DiskAlert;
use AlertHandler::NetworkAlert;
use AlertHandler::ProcessAlert;
use AlertHandler::SslCertAlert;

sub build_chain () {
    my $cpu     = AlertHandler::CpuAlert->new();
    my $memory  = AlertHandler::MemoryAlert->new();
    my $disk    = AlertHandler::DiskAlert->new();
    my $network = AlertHandler::NetworkAlert->new();
    my $process = AlertHandler::ProcessAlert->new();
    my $ssl     = AlertHandler::SslCertAlert->new();

    $cpu->set_next($memory)->set_next($disk)->set_next($network)->set_next($process)->set_next($ssl);

    return $cpu;
}

subtest 'CPU critical alert' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'cpu', severity => 95, source => 'web-01', message => 'CPU 95%'});
    my @log = $chain->get_log();
    ok(grep(/PAGERDUTY.*cpu/,  @log), 'CPU critical triggers PagerDuty');
    ok(grep(/LOG\[CRITICAL\]/, @log), 'CPU critical logged as CRITICAL');
};

subtest 'CPU warning alert' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'cpu', severity => 75, source => 'web-01', message => 'CPU 75%'});
    my @log = $chain->get_log();
    ok(grep(/SLACK.*#alerts.*cpu/, @log), 'CPU warning goes to Slack #alerts');
    ok(grep(/LOG\[WARNING\]/,      @log), 'CPU warning logged as WARNING');
};

subtest 'Memory critical alert' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'memory', severity => 96, source => 'db-01', message => 'Memory 96%'});
    my @log = $chain->get_log();
    ok(grep(/PAGERDUTY/,      @log), 'Memory critical triggers PagerDuty');
    ok(grep(/SLACK.*#alerts/, @log), 'Memory critical goes to Slack');
};

subtest 'OOM process alert' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'process', severity => 100, source => 'app-03', message => 'OOM Killer invoked'});
    my @log = $chain->get_log();
    ok(grep(/PAGERDUTY/, @log), 'OOM triggers PagerDuty');
    is(scalar(grep(/SLACK/, @log)), 2, 'OOM goes to 2 Slack channels');
};

subtest 'Unknown alert type falls through chain' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'cosmic_ray', severity => 42, source => '???', message => 'Bit flip'});
    my @log = $chain->get_log();
    ok(grep(/LOG\[UNKNOWN\]/, @log), 'Unknown type logged as UNKNOWN');
};

subtest 'SSL cert warning' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'ssl_cert', severity => 60, source => 'lb-01', message => 'Cert expires in 14 days'});
    my @log = $chain->get_log();
    ok(grep(/SLACK.*#security/, @log), 'SSL warning goes to #security');
};

subtest 'Chain is extensible - adding new handler' => sub {

    # 新しいハンドラの追加が既存チェーンに影響しないことを検証
    my $chain = build_chain();

    # 既存のアラートが正常に処理される
    $chain->handle({type => 'disk', severity => 92, source => 'storage-01', message => 'Disk 92%'});
    my @log = $chain->get_log();
    ok(grep(/PAGERDUTY/,     @log), 'Disk critical still works in chain');
    ok(grep(/SLACK.*#infra/, @log), 'Disk critical goes to #infra');
};

subtest 'Network critical alert' => sub {
    my $chain = build_chain();
    $chain->handle({type => 'network', severity => 85, source => 'switch-01', message => 'Packet loss 15%'});
    my @log = $chain->get_log();
    ok(grep(/PAGERDUTY/,      @log), 'Network critical triggers PagerDuty');
    ok(grep(/SLACK.*#alerts/, @log), 'Network critical goes to Slack #alerts');
};

done_testing();
