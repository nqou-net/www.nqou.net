#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# Before: コピペコード（Duplicated Code）の例
#
# UserCsvExporter と OrderCsvExporter がほぼ同じ構造を持っているが、
# それぞれ独立に実装されている。バグ修正のたびに両方を直す必要がある。
# ==============================================================================

package UserCsvExporter {
    use Moo;

    sub export ($self) {
        # 1. データ取得（ダミー）
        my @users = (
            { name => 'Aoi',   email => 'aoi@example.com' },
            { name => 'Midori', email => 'midori@example.com' },
        );

        # 2. ヘッダー行の生成
        my @lines = ('name,email');

        # 3. データ行の整形
        for my $row (@users) {
            push @lines, sprintf('%s,%s', $row->{name}, $row->{email});
        }

        # 4. 出力文字列の結合
        return join("\n", @lines) . "\n";
    }
}

package OrderCsvExporter {
    use Moo;

    sub export ($self) {
        # 1. データ取得（ダミー）
        my @orders = (
            { order_id => 1001, product => 'Keyboard',  price => 8500 },
            { order_id => 1002, product => 'Trackball', price => 6200 },
        );

        # 2. ヘッダー行の生成
        my @lines = ('order_id,product,price');

        # 3. データ行の整形
        for my $row (@orders) {
            push @lines, sprintf('%d,%s,%d', $row->{order_id}, $row->{product}, $row->{price});
        }

        # 4. 出力文字列の結合
        return join("\n", @lines) . "\n";
    }
}

# 動作確認
if (!caller) {
    say "【ユーザーCSV】";
    say UserCsvExporter->new->export;
    say "【注文CSV】";
    say OrderCsvExporter->new->export;
}

1;
