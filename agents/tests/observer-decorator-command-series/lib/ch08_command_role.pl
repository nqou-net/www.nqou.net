#!/usr/bin/env perl
# 第8回 コード例1: Command::Role - Commandパターンの基盤
use v5.36;
use Moo::Role;
use namespace::clean;

package Command::Role {
    use Moo::Role;
    use namespace::clean;

    requires 'execute';
    requires 'undo';

    has 'executed' => (is => 'rw', default => 0);

    sub do($self) {
        $self->execute;
        $self->executed(1);
    }

    sub undo_if_executed($self) {
        return unless $self->executed;
        $self->undo;
        $self->executed(0);
    }
}

1;
