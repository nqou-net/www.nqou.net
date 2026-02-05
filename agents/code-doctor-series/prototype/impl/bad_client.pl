#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Goblin;
use Time::HiRes qw(gettimeofday tv_interval);

say "--- Bad Case: Always New ---";

my $start = [gettimeofday];

my @goblins;
for my $i (1 .. 1000) {

    # 毎回 new を呼ぶ (重い初期化が走る)
    my $goblin = Goblin->new(x => $i, y => 0);
    push @goblins, $goblin;
}

my $elapsed = tv_interval($start);
say "Created " . scalar(@goblins) . " goblins in $elapsed seconds.";
