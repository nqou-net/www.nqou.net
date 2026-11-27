#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use feature 'say';

# ==========================================
# Before: Class Explosion (Multi-dimensional Inheritance)
# ==========================================
# 継承関係で「レポートの種類」と「出力形式」を表現しようとして破綻している例

package Before::Report {

    sub new {
        my ($class, %args) = @_;
        return bless {%args}, $class;
    }
    sub generate { die "Abstract method" }
}

# 軸1: レポートの種類 (Daily)
package Before::DailyReport {
    use parent -norequire, 'Before::Report';
    sub get_data {"Today's sales: 100"}    # ダミーデータ
}

# 軸2: 出力形式 (Text) が、軸1と混ざって継承される
package Before::DailyReportText {
    use parent -norequire, 'Before::DailyReport';

    sub generate {
        my $self = shift;
        return "=== Report ===\n" . $self->get_data() . "\n==============";
    }
}

package Before::DailyReportHTML {
    use parent -norequire, 'Before::DailyReport';

    sub generate {
        my $self = shift;
        return "<html><body><h1>Report</h1><p>" . $self->get_data() . "</p></body></html>";
    }
}

# 月報も同様に...
package Before::MonthlyReport {
    use parent -norequire, 'Before::Report';
    sub get_data {"Monthly sales: 3000"}
}

package Before::MonthlyReportText {
    use parent -norequire, 'Before::MonthlyReport';

    sub generate {
        my $self = shift;
        return "=== MONTHLY ===\n" . $self->get_data() . "\n===============";
    }
}

# HTML版も必要... JSON版も必要... XML版も...
# クラス数 = レポート種類(M) × 出力形式(N) => 爆発！

# ==========================================
# After: Bridge Pattern
# ==========================================
# 「機能のクラス階層」と「実装のクラス階層」を分離して委譲で繋ぐ

# ---------------------------------
# Implementor (実装の階層)
# ---------------------------------
package After::Formatter {
    sub new           { bless {}, shift }
    sub format_header { die "Abstract" }
    sub format_body   { die "Abstract" }
    sub format_footer { die "Abstract" }
}

# Concrete Implementor A
package After::TextFormatter {
    use parent -norequire, 'After::Formatter';
    sub format_header {"=== Report ===\n"}
    sub format_body   { my ($self, $data) = @_; "Content: $data\n" }
    sub format_footer {"==============\n"}
}

# Concrete Implementor B
package After::HtmlFormatter {
    use parent -norequire, 'After::Formatter';
    sub format_header {"<html><body><h1>Report</h1>\n"}
    sub format_body   { my ($self, $data) = @_; "<p>$data</p>\n" }
    sub format_footer {"</body></html>\n"}
}

# Concrete Implementor C (New!) - 容易に追加可能
package After::JsonFormatter {
    use parent -norequire, 'After::Formatter';
    sub format_header {"{ \"report\": {\n"}
    sub format_body   { my ($self, $data) = @_; "  \"data\": \"$data\"\n" }
    sub format_footer {"} }\n"}
}

# ---------------------------------
# Abstraction (機能の階層)
# ---------------------------------
package After::Report {

    sub new {
        my ($class, $formatter) = @_;
        return bless {formatter => $formatter}, $class;
    }

    sub display {
        my $self = shift;
        my $f    = $self->{formatter};

        print $f->format_header();
        print $f->format_body($self->get_data());
        print $f->format_footer();
    }

    sub get_data { die "Abstract" }
}

# Refined Abstraction A
package After::DailyReport {
    use parent -norequire, 'After::Report';
    sub get_data {"Daily Statistics Data"}
}

# Refined Abstraction B
package After::MonthlyReport {
    use parent -norequire, 'After::Report';
    sub get_data {"Monthly Analysis Data"}
}

# ==========================================
# Main Execution
# ==========================================
package main;

print "--- Before: Class Explosion ---\n";
my $old_daily_text = Before::DailyReportText->new();
print $old_daily_text->generate() . "\n\n";

my $old_monthly_text = Before::MonthlyReportText->new();
print $old_monthly_text->generate() . "\n\n";

# 新しいフォーマットを追加するには、Before::DailyReportJSON, Before::MonthlyReportJSON...
# と全ての組み合わせを作る必要がある。

print "--- After: Bridge Pattern ---\n";

# 組み合わせは実行時に自由に決定できる (Mix and Match)

my $text_fmt = After::TextFormatter->new();
my $html_fmt = After::HtmlFormatter->new();
my $json_fmt = After::JsonFormatter->new();

# Daily Report x Text
my $daily_text = After::DailyReport->new($text_fmt);
$daily_text->display();
print "\n";

# Monthly Report x HTML
my $monthly_html = After::MonthlyReport->new($html_fmt);
$monthly_html->display();
print "\n";

# Daily Report x JSON (New combination without new subclass!)
my $daily_json = After::DailyReport->new($json_fmt);
$daily_json->display();
print "\n";
