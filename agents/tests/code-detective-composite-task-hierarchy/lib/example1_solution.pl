#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- タスク管理システム（改善版: Composite パターン） ---

# 共通インターフェース（掟）
package TaskComponent {
    use Moo::Role;
    requires 'total_hours';
    requires 'count_completed';
    requires 'count_all';

    has title => ( is => 'ro', required => 1 );

    sub progress ($self) {
        my $total = $self->count_all;
        return 0 unless $total;
        return $self->count_completed / $total * 100;
    }
}

# リーフノード（末端構成員）
package TaskLeaf {
    use Moo;
    with 'TaskComponent';

    has hours     => ( is => 'ro', default => 0 );
    has completed => ( is => 'rw', default => 0 );

    sub total_hours ($self) { $self->hours }
    sub count_completed ($self) { $self->completed ? 1 : 0 }
    sub count_all ($self) { 1 }
}

# コンポジットノード（幹部）
package TaskComposite {
    use Moo;
    with 'TaskComponent';

    has children => ( is => 'ro', default => sub { [] } );

    sub add ($self, $child) {
        push @{$self->children}, $child;
        return $self;
    }

    sub total_hours ($self) {
        my $sum = 0;
        $sum += $_->total_hours for @{$self->children};
        return $sum;
    }

    sub count_completed ($self) {
        my $count = 0;
        $count += $_->count_completed for @{$self->children};
        return $count;
    }

    sub count_all ($self) {
        my $count = 0;
        $count += $_->count_all for @{$self->children};
        return $count;
    }
}

# 新しいノード種（連絡員）— 既存コード修正なし
package Milestone {
    use Moo;
    with 'TaskComponent';

    has reached => ( is => 'rw', default => 0 );

    sub total_hours ($self) { 0 }
    sub count_completed ($self) { $self->reached ? 1 : 0 }
    sub count_all ($self) { 1 }
}

package main {
    if (!caller) {
        my $project = TaskComposite->new(title => 'Website Redesign');

        my $phase1 = TaskComposite->new(title => 'Design Phase');
        $phase1->add(TaskLeaf->new(title => 'Wireframe', hours => 8, completed => 1));
        $phase1->add(TaskLeaf->new(title => 'Mockup', hours => 16, completed => 1));

        my $phase2 = TaskComposite->new(title => 'Implementation');
        $phase2->add(TaskLeaf->new(title => 'Frontend', hours => 40, completed => 0));
        $phase2->add(Milestone->new(title => 'Beta Release', reached => 0));

        $project->add($phase1);
        $project->add($phase2);

        say "Total hours: " . $project->total_hours;
        say "Progress: " . $project->progress . "%";
    }
}

1;
