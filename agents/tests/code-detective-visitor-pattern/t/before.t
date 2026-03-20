use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-visitor-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: Scattered Type Checking' => sub {
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

    # 進捗計算は LiveSessionContent にも対応済み
    is(calc_progress($video), 91, 'Video progress: 91%');
    is(calc_progress($live), 0, 'Live session progress: 0% (not attended)');

    # 採点も LiveSessionContent に対応済み
    is(calc_grade($live), 'fail', 'Live session grade: fail');

    # ★ BUG: check_completion に LiveSessionContent の分岐がない
    # 未参加なのに「修了」と判定される
    is(check_completion($live), 1, 'BUG: Unattended live session marked as COMPLETED');

    # レポート生成は対応済み
    like(generate_report_line($live), qr/absent/, 'Report correctly shows absent');

    # 全コンテンツの修了チェック
    my @contents = ($video, $quiz, $report, $discussion, $live);
    my @completed = grep { check_completion($_) } @contents;
    is(scalar @completed, 5, 'BUG: All 5 marked complete (live should be incomplete)');
};

done_testing;
