#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;

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

package RadarLogObserver;
use Moo;

sub update ($self, $event) {
    say "=== 侵入イベント検知 ===";
    say "時刻: " . $event->timestamp;
    say "発信元: " . $event->source_ip;
    say "攻撃種別: " . $event->attack_type;
    say "";
}

package ThreatScoreObserver;
use Moo;

my %threat_scores = (
    'SSH Brute Force'       => 80,
    'Port Scan'             => 30,
    'SQL Injection Attempt' => 90,
    'XSS Attack'            => 70,
);

has total_score => (
    is      => 'rw',
    default => 0,
);

sub update ($self, $event) {
    my $score = $threat_scores{$event->attack_type} // 50;
    $self->total_score($self->total_score + $score);
    say "[脅威スコア] $score 加算 (累計: " . $self->total_score . ")";
}

package main;

# 通知担当を用意
my $log_observer   = RadarLogObserver->new;
my $score_observer = ThreatScoreObserver->new;

# イベントを作成
my @events = (
    IntrusionEvent->new(
        timestamp   => '2026-01-18T06:00:00+09:00',
        source_ip   => '192.168.1.100',
        attack_type => 'SSH Brute Force',
    ),
    IntrusionEvent->new(
        timestamp   => '2026-01-18T06:01:15+09:00',
        source_ip   => '10.0.0.55',
        attack_type => 'Port Scan',
    ),
);

# 各イベントを処理
for my $event (@events) {
    $log_observer->update($event);
    $score_observer->update($event);
}
