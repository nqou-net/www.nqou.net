#!/usr/bin/env perl
use v5.36;
use JSON::PP;
use YAML::Tiny;

# ========================================
# ExporterRole - エクスポーターの約束
# ========================================
package ExporterRole {
    use Moo::Role;
    requires 'export';
}

# ========================================
# CsvExporterクラス
# ========================================
package CsvExporter {
    use Moo;
    use v5.36;
    with 'ExporterRole';

    sub export ($self, $data) {
        my $output = "name,email,phone\n";
        for my $contact (@$data) {
            $output .= "$contact->{name},$contact->{email},$contact->{phone}\n";
        }
        return $output;
    }
}

# ========================================
# JsonExporterクラス
# ========================================
package JsonExporter {
    use Moo;
    use v5.36;
    use JSON::PP;
    with 'ExporterRole';

    sub export ($self, $data) {
        return JSON::PP->new->pretty->encode($data);
    }
}

# ========================================
# YamlExporterクラス
# ========================================
package YamlExporter {
    use Moo;
    use v5.36;
    use YAML::Tiny;
    with 'ExporterRole';

    sub export ($self, $data) {
        my $yaml = YAML::Tiny->new($data);
        return $yaml->write_string;
    }
}

# ========================================
# DataExporterクラス（エクスポーター管理）
# ========================================
package DataExporter {
    use Moo;
    use v5.36;

    has exporter => (
        is       => 'rw',
        required => 1,
        isa => sub { # 型チェック追加
            my $value = shift;
            die "exporter must does ExporterRole" unless $value->does('ExporterRole')
        },
    );

    # 形式名からエクスポーターを取得するためのマッピング
    my %exporter_map = (
        csv  => 'CsvExporter',
        json => 'JsonExporter',
        yaml => 'YamlExporter',
    );

    # 対応形式の一覧を取得
    sub supported_formats ($class) {
        return sort keys %exporter_map;
    }

    # 形式名からエクスポーターを生成
    sub exporter_for ($class, $format) {
        my $exporter_class = $exporter_map{$format};
        die "未対応の形式です: $format\n対応形式: " . join(', ', $class->supported_formats) . "\n"
            unless $exporter_class;
        return $exporter_class->new;
    }

    sub export_data ($self, $data) {
        return $self->exporter->export($data);
    }
}

# ========================================
# メイン処理
# ========================================
package main;

# アドレス帳データ
my @contacts = (
    { name => '田中太郎', email => 'tanaka@example.com', phone => '090-1234-5678' },
    { name => '鈴木花子', email => 'suzuki@example.com', phone => '080-2345-6789' },
    { name => '佐藤次郎', email => 'sato@example.com',   phone => '070-3456-7890' },
);

# コマンドライン引数から形式を取得
my $format = $ARGV[0] // 'csv';

# ヘルプ表示
if ($format eq '--help' || $format eq '-h') {
    say "使い方: perl exporter.pl [形式]";
    say "対応形式: " . join(', ', DataExporter->supported_formats);
    exit 0;
}

# エクスポート実行
my $exporter = DataExporter->exporter_for($format);
my $data_exporter = DataExporter->new(exporter => $exporter);
print $data_exporter->export_data(\@contacts);
