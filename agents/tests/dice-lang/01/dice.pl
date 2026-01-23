#!/usr/bin/env perl
use v5.36;

package Dice {
    use Moo;

    has count => (is => 'ro', required => 1);
    has sides => (is => 'ro', required => 1);

    sub roll($self) {
        my $total = 0;
        for (1 .. $self->count) {
            $total += int(rand($self->sides)) + 1;
        }
        return $total;
    }

    sub parse($class, $notation) {
        if ($notation =~ /^(\d+)d(\d+)$/) {
            return $class->new(count => $1, sides => $2);
        }
        die "不正なダイス記法: $notation";
    }
}

# 文字列から解析
my $dice = Dice->parse('2d6');
say "2d6の結果: " . $dice->roll;

my $dice2 = Dice->parse('3d8');
say "3d8の結果: " . $dice2->roll;

my $dice3 = Dice->parse('1d20');
say "1d20の結果: " . $dice3->roll;
