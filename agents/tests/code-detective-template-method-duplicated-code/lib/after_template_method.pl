#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# After: Template Method パターンを適用し、コピペコードを統合した例
#
# 共通の骨格（export メソッド）を基底クラスに定義し、
# 差分（データ取得・ヘッダー・行整形）だけをサブクラスでオーバーライドする。
# ==============================================================================

# ----------------------------------
# 1. 基底クラス（Template Method）
# ----------------------------------
package CsvExporter::Base {
    use Moo;

    # Template Method: 処理の骨格を定義
    # サブクラスはこのメソッドを直接オーバーライドしない
    sub export ($self) {
        my @data  = $self->fetch_data();
        my @lines = ($self->header_line());

        for my $row (@data) {
            push @lines, $self->format_row($row);
        }

        return join("\n", @lines) . "\n";
    }

    # サブクラスで必ずオーバーライドすべきメソッド群
    sub fetch_data ($self)      { die ref($self) . "::fetch_data must be overridden" }
    sub header_line ($self)     { die ref($self) . "::header_line must be overridden" }
    sub format_row ($self, $row) { die ref($self) . "::format_row must be overridden" }
}

# ----------------------------------
# 2. サブクラス群（差分だけを定義）
# ----------------------------------
package CsvExporter::User {
    use Moo;
    extends 'CsvExporter::Base';

    sub fetch_data ($self) {
        return (
            { name => 'Aoi',   email => 'aoi@example.com' },
            { name => 'Midori', email => 'midori@example.com' },
        );
    }

    sub header_line ($self) { 'name,email' }

    sub format_row ($self, $row) {
        return sprintf('%s,%s', $row->{name}, $row->{email});
    }
}

package CsvExporter::Order {
    use Moo;
    extends 'CsvExporter::Base';

    sub fetch_data ($self) {
        return (
            { order_id => 1001, product => 'Keyboard',  price => 8500 },
            { order_id => 1002, product => 'Trackball', price => 6200 },
        );
    }

    sub header_line ($self) { 'order_id,product,price' }

    sub format_row ($self, $row) {
        return sprintf('%d,%s,%d', $row->{order_id}, $row->{product}, $row->{price});
    }
}

# 動作確認
if (!caller) {
    say "【ユーザーCSV】";
    say CsvExporter::User->new->export;
    say "【注文CSV】";
    say CsvExporter::Order->new->export;
}

1;
