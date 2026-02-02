#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# ==========================================
# 患部: 巨大なswitch文を抱えるクラス
# ==========================================
package ReportGenerator {

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub generate {
        my ($self, $format, $data) = @_;

        # 症状: 形式が増えるたびにこのメソッドが肥大化する
        # 条件分岐肥大化症 (Conditional Logic Hypertrophy)
        if ($format eq 'CSV') {
            return "CSV Report: " . join(',', @$data);
        }
        elsif ($format eq 'JSON') {

            # 簡易的なJSON形式
            my @quoted = map {qq("$_")} @$data;
            return "JSON Report: [" . join(',', @quoted) . "]";
        }
        elsif ($format eq 'XML') {
            my $xml = "<report>\n";
            for my $item (@$data) {
                $xml .= "  <item>$item</item>\n";
            }
            $xml .= "</report>";
            return "XML Report: $xml";
        }
        else {
            die "Unknown format: $format";
        }
    }
}

# ==========================================
# クライアントコード
# ==========================================
package main;

my $data      = ['Alice', 'Bob', 'Charlie'];
my $generator = ReportGenerator->new();

print $generator->generate('CSV',  $data) . "\n";
print $generator->generate('JSON', $data) . "\n";
print $generator->generate('XML',  $data) . "\n";
