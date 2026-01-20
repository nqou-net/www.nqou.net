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
        say "月次レポートを生成しました。";
    }
}

# ========================================
# WeeklyReport クラス（新規追加）
# ========================================
package WeeklyReport {
    use Moo;

    has title => (
        is       => 'ro',
        required => 1,
    );

    has period => (
        is      => 'ro',
        default => sub { '週次' },
    );

    sub generate ($self) {
        say "=== " . $self->title . " ===";
        say "期間: " . $self->period;
        say "週次レポートを生成しました。";
    }
}

# ========================================
# ReportGenerator クラス
# ========================================
package ReportGenerator {
    use Moo;

    sub create_report ($self, $type, $title) {
        if ($type eq 'monthly') {
            return MonthlyReport->new(title => $title);
        }
        elsif ($type eq 'weekly') {
            return WeeklyReport->new(title => $title);
        }
        else {
            die "Unknown report type: $type";
        }
    }

    sub generate_and_print ($self, $type, $title) {
        my $report = $self->create_report($type, $title);
        $report->generate();
        return $report;
    }
}

# ========================================
# メイン処理
# ========================================
package main;

my $generator = ReportGenerator->new();

say "--- 月次レポート ---";
$generator->generate_and_print('monthly', "2026年1月 売上レポート");

say "";

say "--- 週次レポート ---";
$generator->generate_and_print('weekly', "2026年1月第1週 売上レポート");
