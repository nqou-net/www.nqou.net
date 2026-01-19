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

# 侵入イベントを作成
my $event = IntrusionEvent->new(
    timestamp   => '2026-01-18T06:00:00+09:00',
    source_ip   => '192.168.1.100',
    attack_type => 'SSH Brute Force',
);

# イベント情報を表示
say "=== 侵入イベント検知 ===";
say "時刻: " . $event->timestamp;
say "発信元: " . $event->source_ip;
say "攻撃種別: " . $event->attack_type;
