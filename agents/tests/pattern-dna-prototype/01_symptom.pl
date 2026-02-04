#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);

# Code Doctor Case: Prototype Pattern (Before)
# Patient: Kenji
# Symptom: "The simulation is too slow because I initialize everything from scratch."

package Genome {
    sub new {
        my ($class, $seq) = @_;
        # Simulation of heavy parsing logic (e.g. validating complex rules)
        # Kenji thinks this validation MUST run every time for "safety".
        select(undef, undef, undef, 0.2); # Sleep 200ms
        return bless { sequence => $seq }, $class;
    }
}

package Bacteria {
    sub new {
        my ($class, $dna_seq, $name) = @_;
        # 毎回重いGenome初期化を行っている
        my $genome = Genome->new($dna_seq);
        return bless { genome => $genome, name => $name }, $class;
    }
}

print "--- Simulation Start (Symptom: Initialization Overload) ---\n";
my $start = time;

# 5世代（5匹）作るだけで1秒以上かかる
for my $i (1..5) {
    my $t0 = time;
    my $b = Bacteria->new("ATCG" x 100, "Coli-$i");
    printf "Generated Gen-$i : %.4f sec\n", (time - $t0);
}

my $duration = time - $start;
printf "Total Duration: %.4f sec\n", $duration;
