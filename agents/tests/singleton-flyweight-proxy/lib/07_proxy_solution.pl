#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin";
use FontProxy;

# 第7回: Proxyパターンで必要な文字だけ遅延ロード

package LazyFontLoader {
    use Moo;

    has proxies => (is => 'ro', default => sub { {} });

    # Proxyだけ作成（実際のロードはしない）
    sub BUILD($self, $args) {
        say "フォントプロキシを準備中...";
        for my $char ('A' .. 'Z', '0' .. '9') {
            $self->proxies->{$char} = FontProxy->new(char => $char);
        }
        say "完了！（実際のデータはまだロードされていません）";
    }

    sub get_font($self, $char) {
        return $self->proxies->{uc $char};
    }

    sub loaded_count($self) {
        my $count = 0;
        for my $proxy (values $self->proxies->%*) {
            $count++ if $proxy->is_loaded;
        }
        return $count;
    }
}

package main;

say "=== ASCIIアート・フォントレンダラー v0.7 (Proxy版) ===";
say "";

# 起動時間を計測
my $start   = time();
my $loader  = LazyFontLoader->new;
my $elapsed = time() - $start;

say "";
say sprintf("起動時間: %.4f秒（ほぼ瞬時！）", $elapsed);
say "準備したプロキシ数: " . scalar(keys $loader->proxies->%*);
say "ロード済みフォント数: " . $loader->loaded_count;
say "";

# HELLOを表示
say "「HELLO」を表示:";
my @chars        = qw(H E L L O);
my @result_lines = ("") x 5;

for my $char (@chars) {
    my $proxy = $loader->get_font($char);
    my @lines = $proxy->get_lines;
    for my $i (0 .. 4) {
        $result_lines[$i] .= sprintf("%-6s", $lines[$i] // "");
    }
}
say join("\n", @result_lines);
say "";

say "ロード済みフォント数: " . $loader->loaded_count . " (HELLOで使った4種類だけ)";
say "";

say "*** 改善効果 ***";
say "";
say "Proxyパターンで遅延ロードを実現:";
say "  - 起動は瞬時 (プロキシ作成のみ)";
say "  - 使う文字だけオンデマンドでロード";
say "  - H, E, L, O の4種類だけがロードされた";
say "  - 残り32種類は未ロードのまま";
say "";
say "→ 起動時間もメモリも大幅に節約！";
