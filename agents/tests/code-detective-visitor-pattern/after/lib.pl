use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# --- コンテンツクラス（accept メソッド追加）---

package VideoContent {
    use Moo;
    has id             => ( is => 'ro', required => 1 );
    has title          => ( is => 'ro', required => 1 );
    has duration_min   => ( is => 'ro', required => 1 );
    has watched_min    => ( is => 'rw', default  => 0 );

    sub accept ($self, $visitor) { $visitor->visit_video($self) }
}

package QuizContent {
    use Moo;
    has id              => ( is => 'ro', required => 1 );
    has title           => ( is => 'ro', required => 1 );
    has total_questions => ( is => 'ro', required => 1 );
    has correct_answers => ( is => 'rw', default  => 0 );

    sub accept ($self, $visitor) { $visitor->visit_quiz($self) }
}

package ReportContent {
    use Moo;
    has id         => ( is => 'ro', required => 1 );
    has title      => ( is => 'ro', required => 1 );
    has submitted  => ( is => 'rw', default  => 0 );
    has word_count => ( is => 'rw', default  => 0 );

    sub accept ($self, $visitor) { $visitor->visit_report($self) }
}

package DiscussionContent {
    use Moo;
    has id             => ( is => 'ro', required => 1 );
    has title          => ( is => 'ro', required => 1 );
    has post_count     => ( is => 'rw', default  => 0 );
    has required_posts => ( is => 'ro', default  => 3 );

    sub accept ($self, $visitor) { $visitor->visit_discussion($self) }
}

package LiveSessionContent {
    use Moo;
    has id           => ( is => 'ro', required => 1 );
    has title        => ( is => 'ro', required => 1 );
    has attended     => ( is => 'rw', default  => 0 );
    has duration_min => ( is => 'ro', required => 1 );

    sub accept ($self, $visitor) { $visitor->visit_live_session($self) }
}

# --- Visitor ロール ---

package ContentVisitor {
    use Moo::Role;

    requires 'visit_video';
    requires 'visit_quiz';
    requires 'visit_report';
    requires 'visit_discussion';
    requires 'visit_live_session';
}

# --- 具象 Visitor ---

package ProgressCalculator {
    use Moo;
    with 'ContentVisitor';

    sub visit_video ($self, $v) {
        return $v->duration_min > 0
            ? int($v->watched_min / $v->duration_min * 100)
            : 0;
    }
    sub visit_quiz ($self, $q) {
        return $q->total_questions > 0
            ? int($q->correct_answers / $q->total_questions * 100)
            : 0;
    }
    sub visit_report ($self, $r) {
        return $r->submitted ? 100 : 0;
    }
    sub visit_discussion ($self, $d) {
        my $ratio = $d->required_posts > 0
            ? $d->post_count / $d->required_posts
            : 0;
        return int(($ratio > 1 ? 1 : $ratio) * 100);
    }
    sub visit_live_session ($self, $ls) {
        return $ls->attended ? 100 : 0;
    }
}

package GradeCalculator {
    use Moo;
    with 'ContentVisitor';

    sub visit_video ($self, $v) {
        my $progress = ProgressCalculator->new->visit_video($v);
        return $progress >= 80 ? 'pass' : 'fail';
    }
    sub visit_quiz ($self, $q) {
        return $q->total_questions > 0
            && ($q->correct_answers / $q->total_questions) >= 0.7
            ? 'pass' : 'fail';
    }
    sub visit_report ($self, $r) {
        return $r->submitted && $r->word_count >= 200
            ? 'pass' : 'fail';
    }
    sub visit_discussion ($self, $d) {
        return $d->post_count >= $d->required_posts
            ? 'pass' : 'fail';
    }
    sub visit_live_session ($self, $ls) {
        return $ls->attended ? 'pass' : 'fail';
    }
}

package CompletionChecker {
    use Moo;
    with 'ContentVisitor';

    sub visit_video ($self, $v) {
        my $progress = ProgressCalculator->new->visit_video($v);
        return $progress >= 80 ? 1 : 0;
    }
    sub visit_quiz ($self, $q) {
        return GradeCalculator->new->visit_quiz($q) eq 'pass' ? 1 : 0;
    }
    sub visit_report ($self, $r) {
        return $r->submitted ? 1 : 0;
    }
    sub visit_discussion ($self, $d) {
        return $d->post_count >= $d->required_posts ? 1 : 0;
    }
    sub visit_live_session ($self, $ls) {
        return $ls->attended ? 1 : 0;
    }
}

package ReportGenerator {
    use Moo;
    with 'ContentVisitor';

    sub visit_video ($self, $v) {
        my $progress = ProgressCalculator->new->visit_video($v);
        return sprintf("[Video] %s: %d%% watched", $v->title, $progress);
    }
    sub visit_quiz ($self, $q) {
        return sprintf("[Quiz] %s: %d/%d correct", $q->title, $q->correct_answers, $q->total_questions);
    }
    sub visit_report ($self, $r) {
        return sprintf("[Report] %s: %s (%d words)", $r->title, ($r->submitted ? 'submitted' : 'pending'), $r->word_count);
    }
    sub visit_discussion ($self, $d) {
        return sprintf("[Discussion] %s: %d/%d posts", $d->title, $d->post_count, $d->required_posts);
    }
    sub visit_live_session ($self, $ls) {
        return sprintf("[Live] %s: %s", $ls->title, ($ls->attended ? 'attended' : 'absent'));
    }
}

1;
