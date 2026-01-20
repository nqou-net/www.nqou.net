#!/usr/bin/env perl
use v5.36;

# ========================================
# MonthlyReport クラス
# ========================================
package MonthlyReport {
    use Moo;

    has title => (
        is       => 'ro',
        required => 1,
    );

    has period => (
        is      => 'ro',
        default => sub { '月次' },
    );

    sub generate ($self) {
        say "=== " . $self->title . " ===";
        say "期間: " . $self->period;
        say "レポートを生成しました。";
    }
}

# ========================================
# ReportGenerator クラス
# ========================================
package ReportGenerator {
    use Moo;

    sub create_report ($self, $title) {
        return MonthlyReport->new(title => $title);
    }

    sub generate_and_print ($self, $title) {
        my $report = $self->create_report($title);
        $report->generate();
        return $report;
    }
}

# ========================================
# メイン処理
# ========================================
package main;

my $generator = ReportGenerator->new();
$generator->generate_and_print("2026年1月 売上レポート");
