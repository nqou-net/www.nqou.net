#!/usr/bin/env perl
use v5.36;

# ========================================
# ReportRole ロール（新規追加）
# ========================================
package ReportRole {
    use Moo::Role;

    # このロールを適用するクラスは、
    # 以下のメソッドを必ず実装しなければならない
    requires 'generate';
    requires 'get_period';
}

# ========================================
# MonthlyReport クラス
# ========================================
package MonthlyReport {
    use Moo;
    with 'ReportRole';  # ロールを適用

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
    with 'ReportRole';  # ロールを適用

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
