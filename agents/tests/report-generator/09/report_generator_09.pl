#!/usr/bin/env perl
use v5.36;

# ========================================
# ReportRole ロール
# すべてのレポートが持つべきメソッドを定義
# ========================================
package ReportRole {
    use Moo::Role;

    requires 'generate';
    requires 'get_period';
}

# ========================================
# MonthlyReport クラス
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
            "╔══════════════════════════════════════╗",
            "║ " . $self->title,
            "╠══════════════════════════════════════╣",
            "║ 期間: " . $self->get_period(),
            "║ 種別: 月次売上レポート",
            "╚══════════════════════════════════════╝",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '月次';
    }
}

# ========================================
# WeeklyReport クラス
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
            "┌──────────────────────────────────────┐",
            "│ " . $self->title,
            "├──────────────────────────────────────┤",
            "│ 期間: " . $self->get_period(),
            "│ 種別: 週次売上レポート",
            "└──────────────────────────────────────┘",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '週次';
    }
}

# ========================================
# DailyReport クラス
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
            "+-----------------------------------------+",
            "| " . $self->title,
            "+-----------------------------------------+",
            "| 期間: " . $self->get_period(),
            "| 種別: 日次売上レポート",
            "+-----------------------------------------+",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '日次';
    }
}

# ========================================
# QuarterlyReport クラス
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
            "╔══════════════════════════════════════════╗",
            "║ " . $self->title,
            "╠══════════════════════════════════════════╣",
            "║ 期間: " . $self->get_period(),
            "║ 四半期: Q" . $self->quarter,
            "║ 種別: 四半期業績レポート",
            "╚══════════════════════════════════════════╝",
        );
        return join("\n", @lines);
    }

    sub get_period ($self) {
        return '四半期';
    }
}

# ========================================
# ReportGenerator 基底クラス
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
        say "[INFO] ファイル '$filename' に保存しました。";

        return $report;
    }
}

# ========================================
# MonthlyReportGenerator クラス
# ========================================
package MonthlyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return MonthlyReport->new(title => $title);
    }
}

# ========================================
# WeeklyReportGenerator クラス
# ========================================
package WeeklyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return WeeklyReport->new(title => $title);
    }
}

# ========================================
# DailyReportGenerator クラス
# ========================================
package DailyReportGenerator {
    use Moo;
    extends 'ReportGenerator';

    sub create_report ($self, $title) {
        return DailyReport->new(title => $title);
    }
}

# ========================================
# QuarterlyReportGenerator クラス
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

say "=" x 50;
say " レポートジェネレーター v1.0";
say " 月次・週次・日次・四半期レポートに対応";
say "=" x 50;
say "";

# 月次レポート
say "[1] 月次レポートを生成中...";
my $monthly = MonthlyReportGenerator->new();
$monthly->generate_and_print("2026年1月 売上レポート");
say "";

# 週次レポート
say "[2] 週次レポートを生成中...";
my $weekly = WeeklyReportGenerator->new();
$weekly->generate_and_print("2026年1月 第1週 売上レポート");
say "";

# 日次レポート
say "[3] 日次レポートを生成中...";
my $daily = DailyReportGenerator->new();
$daily->generate_and_print("2026年1月9日 売上レポート");
say "";

# 四半期レポート
say "[4] 四半期レポートを生成中...";
my $q1 = QuarterlyReportGenerator->new(quarter => 1);
$q1->generate_and_print("2026年度 Q1 業績レポート");
say "";

say "=" x 50;
say " すべてのレポートが正常に生成されました！";
say "=" x 50;
