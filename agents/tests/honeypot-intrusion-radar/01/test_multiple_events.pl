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

package main;

# 複数の侵入イベントを作成
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
    IntrusionEvent->new(
        timestamp   => '2026-01-18T06:02:30+09:00',
        source_ip   => '172.16.0.22',
        attack_type => 'SQL Injection Attempt',
    ),
);

# 各イベントを処理
for my $event (@events) {
    say "=== 侵入イベント検知 ===";
    say "時刻: " . $event->timestamp;
    say "発信元: " . $event->source_ip;
    say "攻撃種別: " . $event->attack_type;
    say "";  # 空行で区切り
}
