#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

package Order {
    use Moo;

    # 0: Unpaid (未決済), 1: Preparing (準備中), 2: Shipped (発送済), 3: Cancelled (キャンセル)
    has status => (
        is      => 'rw',
        default => 0,
    );

    has output => (
        is      => 'ro',
        default => sub { [] },
    );

    sub pay ($self) {
        if ($self->status == 0) {
            push @{$self->output}, "Order paid.";
            $self->status(1); # 準備中へ
        }
        elsif ($self->status == 1) {
            push @{$self->output}, "Already paid.";
        }
        elsif ($self->status == 2) {
            push @{$self->output}, "Already shipped.";
        }
        elsif ($self->status == 3) {
            push @{$self->output}, "Cannot pay: Order is cancelled.";
        }
    }

    sub ship ($self) {
        if ($self->status == 0) {
            push @{$self->output}, "Cannot ship: Not paid yet.";
        }
        elsif ($self->status == 1) {
            push @{$self->output}, "Order shipped.";
            $self->status(2); # 発送済へ
        }
        elsif ($self->status == 2) {
            push @{$self->output}, "Already shipped.";
        }
        elsif ($self->status == 3) {
            push @{$self->output}, "Cannot ship: Order is cancelled.";
        }
    }

    sub cancel ($self) {
        if ($self->status == 0) {
            push @{$self->output}, "Order cancelled.";
            $self->status(3); # キャンセルへ
        }
        elsif ($self->status == 1) {
            push @{$self->output}, "Order cancelled and refunded.";
            $self->status(3); # キャンセルへ
        }
        elsif ($self->status == 2) {
            push @{$self->output}, "Cannot cancel: Already shipped.";
        }
        elsif ($self->status == 3) {
            push @{$self->output}, "Already cancelled.";
        }
    }
}
1;
