#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;

# 第2回: 文字が増えるとメモリが爆発する
# A-Zの全文字を個別オブジェクトで作成し、メモリ問題を体験

package Glyph {
    use Moo;

    has name => (is => 'ro', required => 1);
    has art  => (is => 'ro', required => 1);    # ASCIIアートデータ（複数行）

    sub render($self) {
        return $self->art;
    }
}

package main;

# フォントデータ（A-Zまで全部定義）
my %FONT_DATA = (
    A => " AAA\nA   A\nAAAAA\nA   A\nA   A",
    B => "BBBB\nB   B\nBBBB\nB   B\nBBBB",
    C => " CCC\nC\nC\nC\n CCC",
    D => "DDD\nD  D\nD  D\nD  D\nDDD",
    E => "EEEEE\nE\nEEE\nE\nEEEEE",
    F => "FFFFF\nF\nFFF\nF\nF",
    G => " GGG\nG\nG GG\nG  G\n GGG",
    H => "H   H\nH   H\nHHHHH\nH   H\nH   H",
    I => "IIIII\n  I\n  I\n  I\nIIIII",
    J => "JJJJJ\n   J\n   J\nJ  J\n JJ",
    K => "K  K\nK K\nKK\nK K\nK  K",
    L => "L\nL\nL\nL\nLLLLL",
    M => "M   M\nMM MM\nM M M\nM   M\nM   M",
    N => "N   N\nNN  N\nN N N\nN  NN\nN   N",
    O => " OOO\nO   O\nO   O\nO   O\n OOO",
    P => "PPPP\nP   P\nPPPP\nP\nP",
    Q => " QQQ\nQ   Q\nQ Q Q\nQ  Q\n QQ Q",
    R => "RRRR\nR   R\nRRRR\nR R\nR  R",
    S => " SSS\nS\n SSS\n   S\nSSS",
    T => "TTTTT\n  T\n  T\n  T\n  T",
    U => "U   U\nU   U\nU   U\nU   U\n UUU",
    V => "V   V\nV   V\nV   V\n V V\n  V",
    W => "W   W\nW   W\nW W W\nWW WW\nW   W",
    X => "X   X\n X X\n  X\n X X\nX   X",
    Y => "Y   Y\n Y Y\n  Y\n  Y\n  Y",
    Z => "ZZZZZ\n   Z\n  Z\n Z\nZZZZZ",
);

# 問題のあるコード: 文字を使うたびに新しいオブジェクトを生成
sub get_glyph($char) {
    my $art = $FONT_DATA{uc $char} // "  ?\n  ?\n  ?\n  ?\n  ?";
    return Glyph->new(name => $char, art => $art);
}

# 文字列を描画
sub render_text($text) {
    my @glyphs = map { get_glyph($_) } split //, $text;

    # 各行を横に結合
    my @result_lines = ("") x 5;
    for my $glyph (@glyphs) {
        my @art_lines = split /\n/, $glyph->render;
        for my $i (0 .. 4) {
            $result_lines[$i] .= sprintf("%-6s", $art_lines[$i] // "");
        }
    }
    return join("\n", @result_lines);
}

# メイン処理
say "=== ASCIIアート・フォントレンダラー v0.2 ===";
say "";
say "「HELLO」を表示:";
say render_text("HELLO");
say "";

# 問題を示す: 同じ文字Lを2回表示する場合
say "「LOLLOL」を表示（同じ文字が複数回）:";
say render_text("LOLLOL");
say "";

# メモリ使用量の問題を示すメッセージ
say "*** 問題発覚 ***";
say "同じ「L」を3回、「O」を2回使っていますが...";
say "毎回新しいGlyphオブジェクトを作成しています！";
say "";

# 実際のオブジェクト数を数える
my @text      = split //, "LOLLOL";
my $obj_count = scalar @text;
say "文字数: $obj_count";
say "作成されたGlyphオブジェクト数: $obj_count （全部別々！）";
say "";
say "→ 同じ文字なのに複製されてメモリが無駄になっています。";
say "→ 100万文字のテキストを表示したら...？";
