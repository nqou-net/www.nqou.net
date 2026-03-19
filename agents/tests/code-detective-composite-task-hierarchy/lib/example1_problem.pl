#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- タスク管理システム（問題版: 型チェック分岐の散在） ---

package Task {
    use Moo;
    has title     => ( is => 'ro', required => 1 );
    has hours     => ( is => 'ro', default => 0 );
    has completed => ( is => 'rw', default => 0 );
}

package TaskGroup {
    use Moo;
    has title    => ( is => 'ro', required => 1 );
    has children => ( is => 'ro', default => sub { [] } );

    sub add ($self, $child) {
        push @{$self->children}, $child;
    }
}

# すべての操作で ref による型チェックが繰り返される
package TaskUtils {
    use Carp qw(croak);

    sub total_hours ($node) {
        if (ref $node eq 'Task') {
            return $node->hours;
        } elsif (ref $node eq 'TaskGroup') {
            my $sum = 0;
            $sum += total_hours($_) for @{$node->children};
            return $sum;
        } else {
            croak "Unknown node type: " . ref $node;
        }
    }

    sub count_completed ($node) {
        if (ref $node eq 'Task') {
            return $node->completed ? 1 : 0;
        } elsif (ref $node eq 'TaskGroup') {
            my $count = 0;
            $count += count_completed($_) for @{$node->children};
            return $count;
        } else {
            croak "Unknown node type: " . ref $node;
        }
    }

    sub count_all ($node) {
        if (ref $node eq 'Task') {
            return 1;
        } elsif (ref $node eq 'TaskGroup') {
            my $count = 0;
            $count += count_all($_) for @{$node->children};
            return $count;
        } else {
            croak "Unknown node type: " . ref $node;
        }
    }

    sub progress ($node) {
        my $total = count_all($node);
        return 0 unless $total;
        return count_completed($node) / $total * 100;
    }
}

package main {
    if (!caller) {
        my $project = TaskGroup->new(title => 'Project X');
        my $phase1 = TaskGroup->new(title => 'Design');
        $phase1->add(Task->new(title => 'Wireframe', hours => 8, completed => 1));
        $phase1->add(Task->new(title => 'Mockup', hours => 16, completed => 0));
        $project->add($phase1);
        $project->add(Task->new(title => 'Deploy', hours => 2, completed => 0));

        say "Total hours: " . TaskUtils::total_hours($project);
        say "Progress: " . TaskUtils::progress($project) . "%";
    }
}

1;
