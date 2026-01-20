#!/usr/bin/env perl
use v5.36;
use JSON::PP;

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
    );

    # 形式名からエクスポーターを生成するクラスメソッド
    sub exporter_for ($class, $format) {
        my $exporter_class = $exporter_map{$format};
        die "未対応の形式です: $format\n" unless $exporter_class;
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

# 形式名からエクスポーターを生成し、DataExporterを作成
my $exporter = DataExporter->exporter_for($format);
my $data_exporter = DataExporter->new(exporter => $exporter);

# エクスポート実行
print $data_exporter->export_data(\@contacts);
