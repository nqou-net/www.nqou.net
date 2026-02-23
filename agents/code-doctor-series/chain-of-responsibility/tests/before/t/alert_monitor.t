use v5.36;
use Test::More;
use lib 'lib';
use AlertMonitor;

my $monitor = AlertMonitor->new();

subtest 'CPU critical alert' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'cpu', severity => 95, source => 'web-01', message => 'CPU 95%'});
    my @log = $m->get_log();
    ok(grep(/PAGERDUTY.*cpu/,  @log), 'CPU critical triggers PagerDuty');
    ok(grep(/LOG\[CRITICAL\]/, @log), 'CPU critical logged as CRITICAL');
};

subtest 'CPU warning alert' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'cpu', severity => 75, source => 'web-01', message => 'CPU 75%'});
    my @log = $m->get_log();
    ok(grep(/SLACK.*#alerts.*cpu/, @log), 'CPU warning goes to Slack #alerts');
    ok(grep(/LOG\[WARNING\]/,      @log), 'CPU warning logged as WARNING');
};

subtest 'Memory critical alert' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'memory', severity => 96, source => 'db-01', message => 'Memory 96%'});
    my @log = $m->get_log();
    ok(grep(/PAGERDUTY/,      @log), 'Memory critical triggers PagerDuty');
    ok(grep(/SLACK.*#alerts/, @log), 'Memory critical goes to Slack');
};

subtest 'OOM process alert' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'process', severity => 100, source => 'app-03', message => 'OOM Killer invoked'});
    my @log = $m->get_log();
    ok(grep(/PAGERDUTY/, @log), 'OOM triggers PagerDuty');
    is(scalar(grep(/SLACK/, @log)), 2, 'OOM goes to 2 Slack channels');
};

subtest 'Unknown alert type' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'cosmic_ray', severity => 42, source => '???', message => 'Bit flip'});
    my @log = $m->get_log();
    ok(grep(/LOG\[UNKNOWN\]/, @log), 'Unknown type logged as UNKNOWN');
};

subtest 'SSL cert warning' => sub {
    my $m = AlertMonitor->new();
    $m->check_alert({type => 'ssl_cert', severity => 60, source => 'lb-01', message => 'Cert expires in 14 days'});
    my @log = $m->get_log();
    ok(grep(/SLACK.*#security/, @log), 'SSL warning goes to #security');
};

done_testing();
