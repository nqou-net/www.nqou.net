#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

require 'example1_problem.pl';

subtest 'Problem: Type Checking Dispatch' => sub {
    # 基本的なタスクの工数計算
    my $task1 = Task->new(title => 'Design', hours => 8, completed => 1);
    my $task2 = Task->new(title => 'Coding', hours => 16, completed => 0);

    is(TaskUtils::total_hours($task1), 8, 'total_hours for single task');
    is(TaskUtils::count_completed($task1), 1, 'count_completed for done task');
    is(TaskUtils::count_completed($task2), 0, 'count_completed for pending task');

    # グループ化した場合
    my $group = TaskGroup->new(title => 'Phase 1');
    $group->add($task1);
    $group->add($task2);

    is(TaskUtils::total_hours($group), 24, 'total_hours for group');
    is(TaskUtils::count_completed($group), 1, 'count_completed for group');
    is(TaskUtils::count_all($group), 2, 'count_all for group');
    is(TaskUtils::progress($group), 50, 'progress for group');

    # ネストされたグループ
    my $root = TaskGroup->new(title => 'Project');
    my $sub_group = TaskGroup->new(title => 'Sub Phase');
    $sub_group->add(Task->new(title => 'Review', hours => 4, completed => 1));
    $root->add($sub_group);
    $root->add(Task->new(title => 'Deploy', hours => 2, completed => 0));

    is(TaskUtils::total_hours($root), 6, 'total_hours for nested groups');
    is(TaskUtils::count_all($root), 2, 'count_all for nested groups');

    # 問題：新しいノード型を追加すると壊れる
    package MilestoneProto {
        use Moo;
        has title   => ( is => 'ro', required => 1 );
        has reached => ( is => 'rw', default  => 0 );
    }
    my $milestone = MilestoneProto->new(title => 'Beta Release');
    eval { TaskUtils::total_hours($milestone) };
    like($@, qr/Unknown node type/, 'PROBLEM: new node type causes die');
};

subtest 'Solution: Composite Pattern' => sub {
    require 'example1_solution.pl';

    # TaskLeaf の基本動作
    my $leaf = TaskLeaf->new(title => 'Write docs', hours => 4, completed => 1);
    is($leaf->total_hours, 4, 'TaskLeaf total_hours');
    is($leaf->count_completed, 1, 'TaskLeaf count_completed (done)');
    is($leaf->count_all, 1, 'TaskLeaf count_all');

    my $leaf2 = TaskLeaf->new(title => 'Testing', hours => 8, completed => 0);
    is($leaf2->count_completed, 0, 'TaskLeaf count_completed (pending)');

    # TaskComposite の集約動作
    my $group = TaskComposite->new(title => 'Phase 1');
    $group->add($leaf);
    $group->add($leaf2);

    is($group->total_hours, 12, 'TaskComposite aggregates total_hours');
    is($group->count_completed, 1, 'TaskComposite aggregates count_completed');
    is($group->count_all, 2, 'TaskComposite aggregates count_all');

    # progress は Role 内で計算
    is($group->progress, 50, 'progress calculated via Role');

    # 深いネスト構造
    my $project = TaskComposite->new(title => 'Project');
    my $phase1 = TaskComposite->new(title => 'Design');
    $phase1->add(TaskLeaf->new(title => 'Wireframe', hours => 8, completed => 1));
    $phase1->add(TaskLeaf->new(title => 'Mockup', hours => 16, completed => 1));

    my $phase2 = TaskComposite->new(title => 'Implement');
    $phase2->add(TaskLeaf->new(title => 'Frontend', hours => 40, completed => 0));
    $phase2->add(TaskLeaf->new(title => 'Backend', hours => 32, completed => 0));

    $project->add($phase1);
    $project->add($phase2);

    is($project->total_hours, 96, 'deeply nested: total_hours');
    is($project->count_all, 4, 'deeply nested: count_all');
    is($project->count_completed, 2, 'deeply nested: count_completed');
    is($project->progress, 50, 'deeply nested: progress');

    # Milestone を追加 — 既存コード変更なし！
    my $ms = Milestone->new(title => 'Beta Release', reached => 1);
    is($ms->total_hours, 0, 'Milestone: total_hours is 0');
    is($ms->count_completed, 1, 'Milestone: counts as completed when reached');
    is($ms->count_all, 1, 'Milestone: counts as 1 node');

    # Milestone をツリーに統合
    $phase2->add($ms);

    is($project->count_all, 5, 'Milestone integrates: count_all updated');
    is($project->count_completed, 3, 'Milestone integrates: count_completed updated');
    is($project->progress, 60, 'Milestone integrates: progress updated');
    is($project->total_hours, 96, 'Milestone integrates: total_hours unchanged');
};

done_testing;
