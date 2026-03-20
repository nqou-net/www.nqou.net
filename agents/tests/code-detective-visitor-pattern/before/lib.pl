use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package VideoContent {
    use Moo;
    has id             => ( is => 'ro', required => 1 );
    has title          => ( is => 'ro', required => 1 );
    has duration_min   => ( is => 'ro', required => 1 );
    has watched_min    => ( is => 'rw', default  => 0 );
}

package QuizContent {
    use Moo;
    has id             => ( is => 'ro', required => 1 );
    has title          => ( is => 'ro', required => 1 );
    has total_questions => ( is => 'ro', required => 1 );
    has correct_answers => ( is => 'rw', default => 0 );
}

package ReportContent {
    use Moo;
    has id        => ( is => 'ro', required => 1 );
    has title     => ( is => 'ro', required => 1 );
    has submitted => ( is => 'rw', default  => 0 );
    has word_count => ( is => 'rw', default => 0 );
}

package DiscussionContent {
    use Moo;
    has id         => ( is => 'ro', required => 1 );
    has title      => ( is => 'ro', required => 1 );
    has post_count => ( is => 'rw', default  => 0 );
    has required_posts => ( is => 'ro', default => 3 );
}

package LiveSessionContent {
    use Moo;
    has id          => ( is => 'ro', required => 1 );
    has title       => ( is => 'ro', required => 1 );
    has attended    => ( is => 'rw', default  => 0 );
    has duration_min => ( is => 'ro', required => 1 );
}

# --- 操作関数群（ref() による型分岐が散在）---

sub calc_progress ($content) {
    if (ref($content) eq 'VideoContent') {
        return $content->duration_min > 0
            ? int($content->watched_min / $content->duration_min * 100)
            : 0;
    }
    elsif (ref($content) eq 'QuizContent') {
        return $content->total_questions > 0
            ? int($content->correct_answers / $content->total_questions * 100)
            : 0;
    }
    elsif (ref($content) eq 'ReportContent') {
        return $content->submitted ? 100 : 0;
    }
    elsif (ref($content) eq 'DiscussionContent') {
        my $ratio = $content->required_posts > 0
            ? $content->post_count / $content->required_posts
            : 0;
        return int(($ratio > 1 ? 1 : $ratio) * 100);
    }
    elsif (ref($content) eq 'LiveSessionContent') {
        return $content->attended ? 100 : 0;
    }
    else {
        die "Unknown content type: " . ref($content);
    }
}

sub calc_grade ($content) {
    if (ref($content) eq 'VideoContent') {
        return calc_progress($content) >= 80 ? 'pass' : 'fail';
    }
    elsif (ref($content) eq 'QuizContent') {
        return $content->total_questions > 0
            && ($content->correct_answers / $content->total_questions) >= 0.7
            ? 'pass' : 'fail';
    }
    elsif (ref($content) eq 'ReportContent') {
        return $content->submitted && $content->word_count >= 200
            ? 'pass' : 'fail';
    }
    elsif (ref($content) eq 'DiscussionContent') {
        return $content->post_count >= $content->required_posts
            ? 'pass' : 'fail';
    }
    elsif (ref($content) eq 'LiveSessionContent') {
        return $content->attended ? 'pass' : 'fail';
    }
    else {
        die "Unknown content type: " . ref($content);
    }
}

# ★ BUG: LiveSessionContent の分岐が漏れている！
sub check_completion ($content) {
    if (ref($content) eq 'VideoContent') {
        return calc_progress($content) >= 80 ? 1 : 0;
    }
    elsif (ref($content) eq 'QuizContent') {
        return calc_grade($content) eq 'pass' ? 1 : 0;
    }
    elsif (ref($content) eq 'ReportContent') {
        return $content->submitted ? 1 : 0;
    }
    elsif (ref($content) eq 'DiscussionContent') {
        return $content->post_count >= $content->required_posts ? 1 : 0;
    }
    # LiveSessionContent の分岐がない！
    # → 未知の型は暗黙的に「修了」扱いになってしまう
    else {
        return 1;  # ★ デフォルトで修了扱い
    }
}

sub generate_report_line ($content) {
    if (ref($content) eq 'VideoContent') {
        return sprintf("[Video] %s: %d%% watched", $content->title, calc_progress($content));
    }
    elsif (ref($content) eq 'QuizContent') {
        return sprintf("[Quiz] %s: %d/%d correct", $content->title, $content->correct_answers, $content->total_questions);
    }
    elsif (ref($content) eq 'ReportContent') {
        return sprintf("[Report] %s: %s (%d words)", $content->title, ($content->submitted ? 'submitted' : 'pending'), $content->word_count);
    }
    elsif (ref($content) eq 'DiscussionContent') {
        return sprintf("[Discussion] %s: %d/%d posts", $content->title, $content->post_count, $content->required_posts);
    }
    elsif (ref($content) eq 'LiveSessionContent') {
        return sprintf("[Live] %s: %s", $content->title, ($content->attended ? 'attended' : 'absent'));
    }
    else {
        return "[Unknown] " . ref($content);
    }
}

1;
