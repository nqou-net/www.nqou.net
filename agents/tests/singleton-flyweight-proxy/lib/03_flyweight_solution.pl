#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use GlyphFactory;

# 第3回: Flyweightパターンで文字グリフを共有

# ファクトリーを作成
my $factory = GlyphFactory->new;

sub render_text($text) {
    my @glyphs = map { $factory->get_glyph($_) } split //, $text;

    # 各行を横に結合
    my @result_lines = ("") x 5;
    for my $glyph (@glyphs) {
        my @art_lines = $glyph->get_lines;
        for my $i (0 .. 4) {
            $result_lines[$i] .= sprintf("%-6s", $art_lines[$i] // "");
        }
    }
    return join("\n", @result_lines);
}

# メイン処理
say "=== ASCIIアート・フォントレンダラー v0.3 (Flyweight版) ===";
say "";
say "「HELLO」を表示:";
say render_text("HELLO");
say "";

say "現在のプールサイズ: " . $factory->pool_size . "文字";
say "プールの内容: " . join(", ", $factory->pool_keys);
say "";

say "「LOLLOL」を表示:";
say render_text("LOLLOL");
say "";

say "プールサイズ: " . $factory->pool_size . "文字（変わらない！）";
say "プールの内容: " . join(", ", $factory->pool_keys);
say "";

# 改善効果を示す
say "*** 改善効果 ***";
say "「LOLLOL」(6文字)を表示しても:";
say "  - L, O の2種類のGlyphオブジェクトだけ";
say "  - 同じ文字は再利用される";
say "  - メモリ使用量: 文字種類数に比例（文字数ではない）";
say "";
say "→ 100万文字のテキストでも、使用する文字種類分のメモリで済む！";
