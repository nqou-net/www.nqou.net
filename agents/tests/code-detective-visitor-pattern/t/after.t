use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-visitor-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Visitor Pattern' => sub {
    my $video = VideoContent->new(
        id => 'v1', title => 'コンプラ研修動画', duration_min => 60, watched_min => 55,
    );
    my $quiz = QuizContent->new(
        id => 'q1', title => '確認テスト', total_questions => 10, correct_answers => 8,
    );
    my $report = ReportContent->new(
        id => 'r1', title => '感想レポート', submitted => 1, word_count => 300,
    );
    my $discussion = DiscussionContent->new(
        id => 'd1', title => 'グループ討議', post_count => 4, required_posts => 3,
    );
    my $live = LiveSessionContent->new(
        id => 'ls1', title => 'ライブ講義', attended => 0, duration_min => 90,
    );

    my $progress   = ProgressCalculator->new;
    my $grade      = GradeCalculator->new;
    my $completion = CompletionChecker->new;
    my $reporter   = ReportGenerator->new;

    # 進捗計算
    is($video->accept($progress), 91, 'Video progress via Visitor: 91%');
    is($live->accept($progress), 0, 'Live session progress via Visitor: 0%');

    # 採点
    is($quiz->accept($grade), 'pass', 'Quiz grade via Visitor: pass');
    is($live->accept($grade), 'fail', 'Live session grade via Visitor: fail');

    # ★ FIX: 修了判定が正しく動作
    is($live->accept($completion), 0, 'FIX: Unattended live session correctly marked INCOMPLETE');
    is($video->accept($completion), 1, 'Video completion: complete (91% >= 80%)');

    # レポート生成
    like($live->accept($reporter), qr/absent/, 'Report via Visitor shows absent');

    # 全コンテンツの修了チェック
    my @contents = ($video, $quiz, $report, $discussion, $live);
    my @completed = grep { $_->accept($completion) } @contents;
    is(scalar @completed, 4, 'FIX: Only 4 completed (live correctly excluded)');

    # ダブルディスパッチの証明
    is($video->accept($progress), 91, 'Double dispatch: video calls visit_video');
    is($quiz->accept($progress), 80, 'Double dispatch: quiz calls visit_quiz');

    # 新しい Visitor を追加してもコンテンツクラスは変更不要
    {
        package DurationSummary {
            use Moo;
            with 'ContentVisitor';
            sub visit_video ($self, $v)        { $v->duration_min }
            sub visit_quiz ($self, $q)          { 15 }
            sub visit_report ($self, $r)        { 30 }
            sub visit_discussion ($self, $d)    { 20 }
            sub visit_live_session ($self, $ls) { $ls->duration_min }
        }
        my $dur = DurationSummary->new;
        my $total = 0;
        $total += $_->accept($dur) for @contents;
        is($total, 215, 'New Visitor (DurationSummary) works without modifying content classes');
    }
};

done_testing;
