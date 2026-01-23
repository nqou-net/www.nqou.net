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
        say "管制塔: " . $aircraft->flight_number . "を登録";
    }

    sub request_landing($self, $aircraft) {
        if (!$self->runway->is_available) {
            if ($aircraft->is_emergency) {
                say "管制塔: " . $aircraft->flight_number . 
                    " [緊急] 優先キューに追加";
                unshift @{$self->waiting_queue}, $aircraft;
            } else {
                say "管制塔: " . $aircraft->flight_number . 
                    " キューに追加";
                push @{$self->waiting_queue}, $aircraft;
            }
            $aircraft->receive_clearance(0);
            return;
        }
        $self->_grant_landing($aircraft);
    }

    sub _grant_landing($self, $aircraft) {
        $self->runway->occupy($aircraft);
        my $msg = $aircraft->is_emergency ? " [緊急着陸許可]" : " 着陸許可";
        say "管制塔: " . $aircraft->flight_number . $msg;
        $aircraft->receive_clearance(1);
    }

    sub notify_landed($self, $aircraft) {
        $self->runway->release;
        $self->_process_queue;
    }

    sub _process_queue($self) {
        return if @{$self->waiting_queue} == 0;
        my $next = shift @{$self->waiting_queue};
        $self->_grant_landing($next);
    }
}

package Aircraft {
    use Moo;
    with 'Aircraft::Role';

    has flight_number => (is => 'ro', required => 1);
    has is_emergency => (is => 'rw', default => 0);

    sub declare_emergency($self) {
        $self->is_emergency(1);
        say $self->flight_number . ": MAYDAY!";
    }

    sub request_landing($self) {
        $self->tower->request_landing($self);
    }

    sub receive_clearance($self, $cleared) {
        if ($cleared) {
            say $self->flight_number . ": 着陸";
            $self->tower->notify_landed($self);
        }
    }
}

# デモ
my $runway = Runway->new(name => 'A');
my $tower = ControlTower->new(runway => $runway);

my @flights = map { Aircraft->new(flight_number => $_) } 
    qw(JAL123 ANA456 SKY789);

$tower->register($_) for @flights;

say "---";
$_->request_landing for @flights;
