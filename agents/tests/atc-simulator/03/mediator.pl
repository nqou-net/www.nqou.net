#!/usr/bin/env perl
use v5.36;

package ControlTower {
    use Moo;

    has aircrafts => (is => 'ro', default => sub { [] });
    has runway_in_use => (is => 'rw', default => 0);

    sub register($self, $aircraft) {
        push @{$self->aircrafts}, $aircraft;
        $aircraft->tower($self);
        say "管制塔: " . $aircraft->flight_number . "を登録しました";
    }

    sub request_landing($self, $aircraft) {
        if ($self->runway_in_use) {
            say "管制塔: " . $aircraft->flight_number . 
                "、滑走路使用中です。待機してください";
            return 0;
        }
        $self->runway_in_use(1);
        say "管制塔: " . $aircraft->flight_number . "、着陸を許可します";
        return 1;
    }

    sub notify_landed($self, $aircraft) {
        $self->runway_in_use(0);
        say "管制塔: " . $aircraft->flight_number . 
            "の着陸を確認。滑走路クリア";
    }
}

package Aircraft {
    use Moo;

    has flight_number => (is => 'ro', required => 1);
    has tower => (is => 'rw');

    sub request_landing($self) {
        say $self->flight_number . ": 着陸許可をリクエストします";
        if ($self->tower->request_landing($self)) {
            say $self->flight_number . ": 着陸します";
            $self->tower->notify_landed($self);
        } else {
            say $self->flight_number . ": 待機します";
        }
    }
}

# 管制塔を作成
my $tower = ControlTower->new;

# 航空機を作成して登録
my $flight1 = Aircraft->new(flight_number => 'JAL123');
my $flight2 = Aircraft->new(flight_number => 'ANA456');
my $flight3 = Aircraft->new(flight_number => 'SKY789');

$tower->register($flight1);
$tower->register($flight2);
$tower->register($flight3);

say "---";

# 着陸を要求
$flight1->request_landing;
say "---";
$flight2->request_landing;
say "---";
$flight3->request_landing;
