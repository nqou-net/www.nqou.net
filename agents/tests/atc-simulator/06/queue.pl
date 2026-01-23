#!/usr/bin/env perl
use v5.36;

package Aircraft::Role {
    use Moo::Role;
    
    requires 'request_landing';
    requires 'receive_clearance';
    has tower => (is => 'rw');
}

package Runway {
    use Moo;

    has name => (is => 'ro', required => 1);
    has occupied_by => (is => 'rw', default => undef);

    sub is_available($self) {
        return !defined $self->occupied_by;
    }

    sub occupy($self, $aircraft) {
        $self->occupied_by($aircraft);
        say "滑走路" . $self->name . ": " . 
            $aircraft->flight_number . "が使用開始";
    }

    sub release($self) {
        my $aircraft = $self->occupied_by;
        $self->occupied_by(undef);
        say "滑走路" . $self->name . ": " . 
            $aircraft->flight_number . "が使用終了";
    }
}

package ControlTower {
    use Moo;

    has aircrafts => (is => 'ro', default => sub { [] });
    has runway => (is => 'ro', required => 1);
    has waiting_queue => (is => 'ro', default => sub { [] });

    sub register($self, $aircraft) {
        push @{$self->aircrafts}, $aircraft;
        $aircraft->tower($self);
        say "管制塔: " . $aircraft->flight_number . "を登録しました";
    }

    sub request_landing($self, $aircraft) {
        if (!$self->runway->is_available) {
            say "管制塔: " . $aircraft->flight_number . 
                "、滑走路使用中です。キューに追加します";
            push @{$self->waiting_queue}, $aircraft;
            $aircraft->receive_clearance(0);
            return;
        }
        $self->_grant_landing($aircraft);
    }

    sub _grant_landing($self, $aircraft) {
        $self->runway->occupy($aircraft);
        say "管制塔: " . $aircraft->flight_number . 
            "、着陸を許可します";
        $aircraft->receive_clearance(1);
    }

    sub notify_landed($self, $aircraft) {
        $self->runway->release;
        say "管制塔: " . $aircraft->flight_number . 
            "の着陸を確認";
        $self->_process_queue;
    }

    sub _process_queue($self) {
        if (@{$self->waiting_queue} == 0) {
            say "管制塔: 待機中の航空機はありません";
            return;
        }
        my $next = shift @{$self->waiting_queue};
        say "管制塔: 次は" . $next->flight_number . "です";
        $self->_grant_landing($next);
    }
}

package Aircraft {
    use Moo;
    with 'Aircraft::Role';

    has flight_number => (is => 'ro', required => 1);

    sub request_landing($self) {
        say $self->flight_number . ": 着陸許可をリクエストします";
        $self->tower->request_landing($self);
    }

    sub receive_clearance($self, $cleared) {
        if ($cleared) {
            say $self->flight_number . ": 着陸します";
            $self->tower->notify_landed($self);
        } else {
            say $self->flight_number . ": 待機します";
        }
    }
}

# 滑走路と管制塔を作成
my $runway = Runway->new(name => 'A');
my $tower = ControlTower->new(runway => $runway);

# 航空機を作成して登録
my $flight1 = Aircraft->new(flight_number => 'JAL123');
my $flight2 = Aircraft->new(flight_number => 'ANA456');
my $flight3 = Aircraft->new(flight_number => 'SKY789');

$tower->register($flight1);
$tower->register($flight2);
$tower->register($flight3);

say "=== 全機が同時に着陸をリクエスト ===";

# 全機が同時に着陸をリクエスト
$flight1->request_landing;
say "---";
$flight2->request_landing;
say "---";
$flight3->request_landing;
