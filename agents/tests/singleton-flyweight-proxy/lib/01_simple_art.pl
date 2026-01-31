#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;

# 第1回: 巨大な文字を表示してみよう
# ハードコードで1文字をASCIIアートで表示する最も単純な実装

sub render_H {
    return <<"END_ART";
 H   H
 H   H
 HHHHH
 H   H
 H   H
END_ART
}

sub render_E {
    return <<"END_ART";
 EEEEE
 E
 EEE
 E
 EEEEE
END_ART
}

sub render_L {
    return <<"END_ART";
 L
 L
 L
 L
 LLLLL
END_ART
}

sub render_O {
    return <<"END_ART";
  OOO
 O   O
 O   O
 O   O
  OOO
END_ART
}

# メイン処理
say "=== ASCIIアート・フォントレンダラー v0.1 ===";
say "";
say "「HELLO」を表示します:";
say "";

# 各文字を順番に表示
my @lines_H = split /\n/, render_H();
my @lines_E = split /\n/, render_E();
my @lines_L = split /\n/, render_L();
my @lines_O = split /\n/, render_O();

# 横に並べて表示
for my $i (0..4) {
    say join("  ", 
        $lines_H[$i] // "",
        $lines_E[$i] // "",
        $lines_L[$i] // "",
        $lines_L[$i] // "",  # 2つ目のL
        $lines_O[$i] // ""
    );
}

say "";
say "完成！巨大な文字が表示できました。";
