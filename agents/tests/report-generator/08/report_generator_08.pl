#!/usr/bin/env perl
use v5.36;

# ========================================
# ReportRole ロール
# ========================================
package ReportRole {
    use Moo::Role;

    requires 'generate';
    requires 'get_period';
}

# ========================================
# MonthlyReport クラス（既存・変更なし）
# ========================================
package MonthlyReport {
    use Moo;
    with 'ReportRole';

    has title => (
        is       => 'ro',
        required => 1,
    );

    sub generate ($self) {
        my @lines = (
            "=== " . $self->title . " ===",
            "期間: " . $self->get_period(),
            "月次レポートを生成しました。",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '月次';
    }
}

# ========================================
# WeeklyReport クラス（既存・変更なし）
# ========================================
package WeeklyReport {
    use Moo;
    with 'ReportRole';

    has title => (
        is       => 'ro',
        required => 1,
    );

    sub generate ($self) {
        my @lines = (
            "=== " . $self->title . " ===",
            "期間: " . $self->get_period(),
            "週次レポートを生成しました。",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '週次';
    }
}

# ========================================
# DailyReport クラス（既存・変更なし）
# ========================================
package DailyReport {
    use Moo;
    with 'ReportRole';

    has title => (
        is       => 'ro',
        required => 1,
    );

    sub generate ($self) {
        my @lines = (
            "=== " . $self->title . " ===",
            "期間: " . $self->get_period(),
            "日次レポートを生成しました。",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '日次';
    }
}

# ========================================
# QuarterlyReport クラス（★新規追加★）
# ========================================
package QuarterlyReport {
    use Moo;
    with 'ReportRole';

    has title => (
        is       => 'ro',
        required => 1,
    );

    has quarter => (
        is       => 'ro',
        required => 1,
    );

    sub generate ($self) {
        my @lines = (
            "=== " . $self->title . " ===",
            "期間: " . $self->get_period(),
            "四半期: Q" . $self->quarter,
            "四半期レポートを生成しました。",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '四半期';
    }
}

# ========================================
# ReportGenerator 基底クラス（既存・変更なし）
# ========================================
package ReportGenerator {
    use Moo;
    use Scalar::Util qw(blessed);

    sub create_report ($self, $title) {
        die "create_report() must be implemented by subclass";
    }

    sub create_validated_report ($self, $title) {
        my $report = $self->create_report($title);

        unless (blessed($report) && $report->does('ReportRole')) {
            die "create_report() must return an object that does ReportRole";
        }

        return $report;
    }

    sub generate_and_print ($self, $title) {
        my $report = $self->create_validated_report($title);
        my $content = $report->generate();
        say $content;
        return $report;
    }

    sub generate_and_save ($self, $title, $filename) {
        my $report = $self->create_validated_report($title);
        my $content = $report->generate();

        say $content;
        say "";
        say "[保存] $filename に保存しました。";

        return $report;
    }
}

# ========================================
# MonthlyReportGenerator クラス（既存・変更なし）
# ========================================
package MonthlyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return MonthlyReport->new(title => $title);
    }
}

# ========================================
# WeeklyReportGenerator クラス（既存・変更なし）
# ========================================
package WeeklyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return WeeklyReport->new(title => $title);
    }
}

# ========================================
# DailyReportGenerator クラス（既存・変更なし）
# ========================================
package DailyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return DailyReport->new(title => $title);
    }
}

# ========================================
# QuarterlyReportGenerator クラス（★新規追加★）
# ========================================
package QuarterlyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    has quarter => (
        is       => 'ro',
        required => 1,
    );

    sub create_report ($self, $title) {
        return QuarterlyReport->new(
            title   => $title,
            quarter => $self->quarter,
        );
    }
}

# ========================================
# メイン処理
# ========================================
package main;

say "=== 全種類のレポート生成 ===";
say "";

say "--- 月次レポート ---";
my $monthly = MonthlyReportGenerator->new();
$monthly->generate_and_print("2026年1月 売上レポート");

say "";

say "--- 週次レポート ---";
my $weekly = WeeklyReportGenerator->new();
$weekly->generate_and_print("2026年1月第1週 売上レポート");

say "";

say "--- 日次レポート ---";
my $daily = DailyReportGenerator->new();
$daily->generate_and_print("2026年1月9日 売上レポート");

say "";

say "--- 四半期レポート（★新規★）---";
my $quarterly = QuarterlyReportGenerator->new(quarter => 1);
$quarterly->generate_and_print("2026年度Q1 業績レポート");
