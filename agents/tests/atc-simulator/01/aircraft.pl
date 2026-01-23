#!/usr/bin/env perl
use v5.36;

package Aircraft {
    use Moo;

    has flight_number => (is => 'ro', required => 1);

    sub request_takeoff($self) {
        say $self->flight_number . ": 離陸します";
    }

    sub request_landing($self) {
        say $self->flight_number . ": 着陸します";
    }
}

# 2機の航空機を作成
my $flight1 = Aircraft->new(flight_number => 'JAL123');
my $flight2 = Aircraft->new(flight_number => 'ANA456');

# それぞれ離陸と着陸
$flight1->request_takeoff;
$flight2->request_takeoff;
$flight1->request_landing;
$flight2->request_landing;
