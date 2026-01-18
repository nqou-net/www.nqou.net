package LogParser;
use Moo;
use strict;
use warnings;
use experimental qw(signatures);
use namespace::clean;

# LogReaderを継承する
extends 'LogReader';

# Combined Log Formatの正規表現
# 名前付きキャプチャ (?<name>...) を使用
my $LOG_REGEX = qr{^
    (?<ip>[\d\.]+)                  # IPアドレス
    \s-\s-\s
    \[(?<datetime>[^\]]+)\]         # 日時
    \s"
    (?<method>[A-Z]+)\s             # メソッド
    (?<path>[^\s]+)\s               # パス
    [^"]+"
    \s
    (?<status>\d+)                  # ステータスコード
    \s
    (?<size>\d+|-)                  # サイズ
}x;

# LogReaderのnext_lineを使って1行読み、パースして返す
sub next_log ($self) {
    while (defined(my $line = $self->next_line)) {
        if ($line =~ $LOG_REGEX) {
            # 名前付きキャプチャの結果（%+）をハッシュリファレンスのコピーとして返す
            return { %+ };
        }
        # マッチしない行（空行や壊れたログ）はスキップして次へ
        warn "Skipped invalid line: $line\n";
    }
    return undef;
}

1;
