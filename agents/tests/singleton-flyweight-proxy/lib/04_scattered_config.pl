#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;

# 第4回: 設定が散らばる問題
# フォントパスや設定が複数箇所でハードコードされている

use FindBin;
use lib "$FindBin::Bin";
use GlyphFactory;

# 問題: 設定が複数箇所に散らばっている

my $FONT_PATH     = "/usr/share/fonts/ascii/standard.fnt";    # 設定1箇所目
my $DEFAULT_STYLE = "bold";                                   # 設定2箇所目

sub initialize_renderer {
    my $font_path = "/usr/share/fonts/ascii/standard.fnt";    # 設定3箇所目（重複！）
    say "フォントを$font_pathから読み込んでいます...";
}

sub get_font_style {
    return "bold";                                            # 設定4箇所目（重複！）
}

sub render_with_style {
    my $style = "bold";                                       # 設定5箇所目（またもや重複！）
                                                              # ...実際のレンダリング処理
}

# メイン処理
say "=== ASCIIアート・フォントレンダラー v0.4 ===";
say "";
say "現在の設定:";
say "  フォントパス: $FONT_PATH";
say "  デフォルトスタイル: $DEFAULT_STYLE";
say "";

initialize_renderer();
say "";

# 問題点を示す
say "*** 問題発覚 ***";
say "";
say "同じ設定が複数箇所にハードコードされています:";
say "";
say "1. \$FONT_PATH = \"/usr/share/fonts/ascii/standard.fnt\"";
say "2. \$DEFAULT_STYLE = \"bold\"";
say "3. initialize_renderer() 内でも同じパス";
say "4. get_font_style() 内でも同じスタイル";
say "5. render_with_style() 内でも同じスタイル";
say "";
say "→ フォントパスを変更したい場合、5箇所を修正する必要がある！";
say "→ 修正漏れがあるとバグの原因に...";
say "→ DRY原則（Don't Repeat Yourself）に違反！";
