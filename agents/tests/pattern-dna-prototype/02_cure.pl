#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Storable    qw(dclone);

# Code Doctor Case: Prototype Pattern (After)
# Doctor's Prescription: Use clone() to bypass heavy initialization.

package Genome {

    sub new {
        my ($class, $seq) = @_;

        # 重い初期化処理はそのまま（変える必要はない）
        select(undef, undef, undef, 0.2);
        return bless {sequence => $seq}, $class;
    }
}

package Bacteria {
    use Storable qw(dclone);    # Import dclone into this package scope

    # Prototype Interface
    sub new {
        my ($class, $dna_seq, $name) = @_;
        my $genome = Genome->new($dna_seq);
        return bless {genome => $genome, name => $name}, $class;
    }

    # The Cure: Cloning
    sub clone {
        my ($self) = @_;

        # Deep Copy is crucial here if Genome is mutable.
        # Storable::dclone provides a safe deep copy.
        return dclone($self);

        # Note: If performance is absolutely critical and objects are shallow,
        # manual hash copy might be even faster, but dclone is safer for general use.
    }

    sub set_name {
        my ($self, $name) = @_;
        $self->{name} = $name;
    }
}

print "--- Simulation Start (Cure: Prototype Cloning) ---\n";
my $start = time;

# 1. Create the Prototype (Accept the cost once)
print "Initializing Prototype...\n";
my $prototype = Bacteria->new("ATCG" x 100, "Prototype-001");

# 2. Clone Loop
for my $i (1 .. 5) {
    my $t0 = time;

    # Clone it!
    my $clone = $prototype->clone();

    # Customize it!
    $clone->set_name("Coli-$i");
    printf "Generated Gen-$i : %.4f sec\n", (time - $t0);
}

my $duration = time - $start;
printf "Total Duration: %.4f sec\n", $duration;
