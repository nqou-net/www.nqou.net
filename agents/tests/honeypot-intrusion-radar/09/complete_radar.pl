#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;

#--------------------------------------------------
# イベントクラス
#--------------------------------------------------
package IntrusionEvent;
use Moo;

has timestamp => (
    is       => 'ro',
    required => 1,
);

has source_ip => (
    is       => 'ro',
    required => 1,
);

has attack_type => (
    is       => 'ro',
    required => 1,
);

#--------------------------------------------------
# Observer契約（Role）
#--------------------------------------------------
package IntrusionObserver;
use Moo::Role;

requires 'update';

#--------------------------------------------------
# 各種Observer
#--------------------------------------------------
package RadarLogObserver;
use Moo;
with 'IntrusionObserver';

sub update ($self, $event) {
    say "[LOG] " . $event->timestamp;
    say "      Type: " . $event->attack_type;
    say "      From: " . $event->source_ip;
}

package ThreatScoreObserver;
use Moo;
with 'IntrusionObserver';

my %threat_scores = (
    'SSH Brute Force'       => 80,
    'Port Scan'             => 30,
    'SQL Injection Attempt' => 90,
    'XSS Attack'            => 70,
    'Directory Traversal'   => 60,
);

has total_score => (
    is      => 'rw',
    default => 0,
);

sub update ($self, $event) {
    my $score = $threat_scores{$event->attack_type} // 50;
    $self->total_score($self->total_score + $score);
    say "[SCORE] +" . $score . " = " . $self->total_score . " total";
}

package RiskLevelObserver;
use Moo;
with 'IntrusionObserver';

my %risk_levels = (
    'SSH Brute Force'       => 'HIGH',
    'Port Scan'             => 'LOW',
    'SQL Injection Attempt' => 'HIGH',
    'XSS Attack'            => 'MEDIUM',
    'Directory Traversal'   => 'MEDIUM',
);

sub update ($self, $event) {
    my $level = $risk_levels{$event->attack_type} // 'MEDIUM';
    my $bar = $level eq 'HIGH'   ? '████████████████'
            : $level eq 'MEDIUM' ? '████████████'
            : '████████';
    say "[RISK] $bar $level";
}

package AlertObserver;
use Moo;
with 'IntrusionObserver';

sub update ($self, $event) {
    say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
    say "!!! ALERT: Intrusion Detected !!!";
    say "!!! " . $event->attack_type . " from " . $event->source_ip;
    say "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
}

#--------------------------------------------------
# 司令塔（Subject）
#--------------------------------------------------
package IntrusionHub;
use Moo;

has observers => (
    is      => 'ro',
    default => sub { [] },
);

sub attach ($self, $observer) {
    unless ($observer->does('IntrusionObserver')) {
        die "Error: IntrusionObserverロールを実装していません";
    }
    push $self->observers->@*, $observer;
}

sub detach ($self, $observer) {
    $self->observers->@* = grep { $_ != $observer } $self->observers->@*;
}

sub notify ($self, $event) {
    for my $observer ($self->observers->@*) {
        $observer->update($event);
    }
}

#--------------------------------------------------
# メイン処理
#--------------------------------------------------
package main;

say "╔══════════════════════════════════════════════╗";
say "║   HONEYPOT INTRUSION RADAR - COMMAND CENTER  ║";
say "╚══════════════════════════════════════════════╝";
say "";

# 司令塔を作成
my $hub = IntrusionHub->new;

# 常駐Observer
$hub->attach(RadarLogObserver->new);
$hub->attach(ThreatScoreObserver->new);
$hub->attach(RiskLevelObserver->new);

# 深夜帯用（今回はデモ用に常時ON）
my $alert = AlertObserver->new;
$hub->attach($alert);

# 侵入イベントをシミュレート
my @events = (
    IntrusionEvent->new(
        timestamp   => '2026-01-18T02:15:33+09:00',
        source_ip   => '203.0.113.42',
        attack_type => 'SSH Brute Force',
    ),
    IntrusionEvent->new(
        timestamp   => '2026-01-18T02:17:45+09:00',
        source_ip   => '198.51.100.77',
        attack_type => 'Port Scan',
    ),
    IntrusionEvent->new(
        timestamp   => '2026-01-18T02:20:12+09:00',
        source_ip   => '192.0.2.123',
        attack_type => 'SQL Injection Attempt',
    ),
);

for my $event (@events) {
    say "──────────────────────────────────────────────";
    $hub->notify($event);
    say "";
}

say "──────────────────────────────────────────────";
say "[RADAR] All events processed.";
