use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === Before: God Method（巨大な処理メソッド） ===
# バリデーション、変換、整形、合計計算がすべて一つのメソッドに詰め込まれている。

# --- CsvImporter（アンチパターン: 全処理が一つのメソッド） ---
package CsvImporter {
    use Moo;

    sub import_csv ($self, $lines) {
        my @results;
        my $is_header = 1;
        for my $line (@$lines) {
            # 空行スキップ
            next if $line =~ /^\s*$/;

            # ヘッダースキップ
            if ($is_header) {
                $is_header = 0;
                next;
            }

            # カラム分割
            my @cols = split /,/, $line;

            # バリデーション: カラム数チェック
            next unless @cols == 3;

            # カラム変換: 名前のトリム、金額の数値化
            my $name   = $cols[0];
            $name =~ s/^\s+|\s+$//g;
            my $amount = $cols[1];
            $amount =~ s/[^0-9]//g;
            my $date   = $cols[2];
            $date =~ s/^\s+|\s+$//g;

            # バリデーション: 金額が正の数
            next unless $amount > 0;

            push @results, { name => $name, amount => int($amount), date => $date };
        }

        # 合計計算
        my $total = 0;
        $total += $_->{amount} for @results;

        return { records => \@results, total => $total };
    }
}

1;
