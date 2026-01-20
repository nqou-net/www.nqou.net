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
# ReportGenerator 基底クラス
# ========================================
package ReportGenerator {
    use Moo;

    # サブクラスでオーバーライドするメソッド
    sub create_report ($self, $title) {
        die "create_report() must be implemented by subclass";
    }

    # 共通の処理: レポートを生成して表示
    sub generate_and_print ($self, $title) {
        my $report = $self->create_report($title);
        my $content = $report->generate();
        say $content;
        return $report;
    }

    # 共通の処理: レポートを生成して保存
    sub generate_and_save ($self, $title, $filename) {
        # 1. レポートを生成
        my $report = $self->create_report($title);

        # 2. レポートの内容を取得
        my $content = $report->generate();

        # 3. 画面に表示
        say $content;

        # 4. ファイルに保存（シミュレーション）
        say "";
        say "[保存] $filename に保存しました。";

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
# メイン処理
# ========================================
package main;

say "=== generate_and_save の使用例 ===";
say "";

my $monthly = MonthlyReportGenerator->new();
$monthly->generate_and_save(
    "2026年1月 売上レポート",
    "monthly_report_202601.txt"
);

say "";

my $weekly = WeeklyReportGenerator->new();
$weekly->generate_and_save(
    "2026年1月第1週 売上レポート",
    "weekly_report_202601_w1.txt"
);
