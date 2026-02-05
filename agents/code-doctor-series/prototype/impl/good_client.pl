#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Goblin;
use Time::HiRes qw(gettimeofday tv_interval);

say "--- Good Case: Prototype Clone ---";

my $start = [gettimeofday];

# 1. 原本(Prototype)を作る
my $proto = Goblin->new(x => 0, y => 0);

my @goblins;
push @goblins, $proto;

# 2. クローンで増やす
for my $i (1 .. 999) {

    # 重い初期化をスキップしてメモリコピーのみ
    my $clone = $proto->clone;
    $clone->x($i);    # 必要な差分だけ適用
    push @goblins, $clone;
}

my $elapsed = tv_interval($start);
say "Created " . scalar(@goblins) . " goblins in $elapsed seconds.";
