#!/usr/bin/env perl
use v5.36;

package Aircraft::Role {
    use Moo::Role;

    
    requires 'request_landing';
    requires 'receive_clearance';

    has tower => (is => 'rw');
}

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
                "、滑走路使用中です";
            $aircraft->receive_clearance(0);
            return;
        }
        $self->runway_in_use(1);
        say "管制塔: " . $aircraft->flight_number . 
            "、着陸を許可します";
        $aircraft->receive_clearance(1);
    }

    sub notify_landed($self, $aircraft) {
        $self->runway_in_use(0);
        say "管制塔: " . $aircraft->flight_number . 
            "の着陸を確認。滑走路クリア";
    }
}

package PassengerAircraft {
    use Moo;
    with 'Aircraft::Role';

    has flight_number => (is => 'ro', required => 1);
    has passengers => (is => 'ro', default => 0);

    sub request_landing($self) {
        say $self->flight_number . 
            "（旅客機）: 着陸許可をリクエストします";
        $self->tower->request_landing($self);
    }

    sub receive_clearance($self, $cleared) {
        if ($cleared) {
            say $self->flight_number . ": 着陸許可を受信。着陸します";
            $self->tower->notify_landed($self);
        } else {
            say $self->flight_number . ": 待機指示を受信。待機します";
        }
    }
}

package CargoAircraft {
    use Moo;
    with 'Aircraft::Role';

    has flight_number => (is => 'ro', required => 1);
    has cargo_weight => (is => 'ro', default => 0);

    sub request_landing($self) {
        say $self->flight_number . 
            "（貨物機）: 着陸許可をリクエストします";
        $self->tower->request_landing($self);
    }

    sub receive_clearance($self, $cleared) {
        if ($cleared) {
            say $self->flight_number . ": 着陸許可を受信。着陸します";
            $self->tower->notify_landed($self);
        } else {
            say $self->flight_number . ": 待機指示を受信。待機します";
        }
    }
}

# 管制塔を作成
my $tower = ControlTower->new;

# 旅客機と貨物機を作成
my $passenger = PassengerAircraft->new(
    flight_number => 'JAL123',
    passengers => 180
);
my $cargo = CargoAircraft->new(
    flight_number => 'FDX456',
    cargo_weight => 50000
);

$tower->register($passenger);
$tower->register($cargo);

say "---";

$passenger->request_landing;
say "---";
$cargo->request_landing;
