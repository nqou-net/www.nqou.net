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
        say "=== " . $self->title . " ===";
        say "期間: " . $self->get_period();
        say "月次レポートを生成しました。";
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
        say "=== " . $self->title . " ===";
        say "期間: " . $self->get_period();
        say "週次レポートを生成しました。";
    }

    sub get_period ($self) {
        return '週次';
    }
}

# ========================================
# ReportGenerator 基底クラス
# ========================================
package ReportGenerator {
    use Moo;

    # サブクラスでオーバーライドするメソッド
    sub create_report ($self, $title) {
        die "create_report() must be implemented by subclass";
    }

    # 共通の処理
    sub generate_and_print ($self, $title) {
        my $report = $self->create_report($title);
        $report->generate();
        return $report;
    }
}

# ========================================
# MonthlyReportGenerator クラス
# ========================================
package MonthlyReportGenerator {
    use Moo;
    extends 'ReportGenerator';  # 継承

    sub create_report ($self, $title) {
        return MonthlyReport->new(title => $title);
    }
}

# ========================================
# WeeklyReportGenerator クラス
# ========================================
package WeeklyReportGenerator {
    use Moo;
    extends 'ReportGenerator';  # 継承

    sub create_report ($self, $title) {
        return WeeklyReport->new(title => $title);
    }
}

# ========================================
# メイン処理
# ========================================
package main;

say "--- 月次レポート ---";
my $monthly_generator = MonthlyReportGenerator->new();
$monthly_generator->generate_and_print("2026年1月 売上レポート");

say "";

say "--- 週次レポート ---";
my $weekly_generator = WeeklyReportGenerator->new();
$weekly_generator->generate_and_print("2026年1月第1週 売上レポート");
