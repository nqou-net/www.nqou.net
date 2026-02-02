#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# ==========================================
# Product (製品) インターフェース
# ==========================================
package Report {
    sub render { die "Override me!" }
}

# ==========================================
# Concrete Products (具体的な製品)
# ==========================================
package CSVReport {
    use parent -norequire, 'Report';

    sub render {
        my ($self, $data) = @_;
        return "CSV Report: " . join(',', @$data);
    }
}

package JSONReport {
    use parent -norequire, 'Report';

    sub render {
        my ($self, $data) = @_;
        my @quoted = map {qq("$_")} @$data;
        return "JSON Report: [" . join(',', @quoted) . "]";
    }
}

package XMLReport {
    use parent -norequire, 'Report';

    sub render {
        my ($self, $data) = @_;
        my $xml = "<report>\n";
        for my $item (@$data) {
            $xml .= "  <item>$item</item>\n";
        }
        $xml .= "</report>";
        return "XML Report: $xml";
    }
}

# ==========================================
# Creator (作成者) クラス
# ==========================================
package ReportGenerator {

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    # Factory Method (サブクラスで実装)
    sub create_report {
        die "Override me!";
    }

    # Template Method的に利用
    sub generate {
        my ($self, $data) = @_;
        my $report = $self->create_report();
        return $report->render($data);
    }
}

# ==========================================
# Concrete Creators (具体的な作成者)
# ==========================================
package CSVGenerator {
    use parent -norequire, 'ReportGenerator';
    sub create_report { return bless {}, 'CSVReport'; }
}

package JSONGenerator {
    use parent -norequire, 'ReportGenerator';
    sub create_report { return bless {}, 'JSONReport'; }
}

package XMLGenerator {
    use parent -norequire, 'ReportGenerator';
    sub create_report { return bless {}, 'XMLReport'; }
}

# ==========================================
# クライアントコード
# ==========================================
package main;

my $data = ['Alice', 'Bob', 'Charlie'];

# クライアントは具体的なGeneratorを選ぶ
# (論理構造が変化: フォーマット文字列ではなく、クラスを選択)

my $csv_gen = CSVGenerator->new();
print $csv_gen->generate($data) . "\n";

my $json_gen = JSONGenerator->new();
print $json_gen->generate($data) . "\n";

my $xml_gen = XMLGenerator->new();
print $xml_gen->generate($data) . "\n";
