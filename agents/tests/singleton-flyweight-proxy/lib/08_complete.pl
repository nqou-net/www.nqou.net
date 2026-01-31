#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin";

# 第8回: 3つのパターンで完成！統合版
# Singleton + Flyweight + Proxy を組み合わせた最終版

use FontManager;
use Glyph;
use GlyphFactory;
use FontProxy;
use RealFont;

# ===== ASCIIアートレンダラー完成版 =====

package ASCIIArtRenderer {
    use Moo;
    use FontManager;
    use GlyphFactory;
    use FontProxy;

    # 共有リソース
    has glyph_factory => (
        is      => 'ro',
        default => sub { GlyphFactory->new },
    );

    has font_proxies => (
        is      => 'ro',
        default => sub { {} },
    );

    # Proxyを取得（遅延生成）
    sub _get_proxy($self, $char) {
        my $key = uc $char;
        $self->font_proxies->{$key} //= FontProxy->new(char => $key);
        return $self->font_proxies->{$key};
    }

    # テキストをレンダリング
    sub render($self, $text) {
        my $manager = FontManager->instance;
        my $spacing = $manager->char_spacing;

        # Flyweightから共有Glyphを取得
        my @glyphs = map { $self->glyph_factory->get_glyph($_) } split //, $text;

        # 各行を横に結合
        my @result_lines = ("") x 5;
        for my $glyph (@glyphs) {
            my @art_lines = $glyph->get_lines;
            for my $i (0 .. 4) {
                $result_lines[$i] .= sprintf("%-" . (5 + $spacing) . "s", $art_lines[$i] // "");
            }
        }
        return join("\n", @result_lines);
    }

    # 統計情報を表示
    sub show_stats($self) {
        say "=== レンダラー統計情報 ===";
        say "Glyphプールサイズ: " . $self->glyph_factory->pool_size . "種類";
        say "プール内容: " . join(", ", $self->glyph_factory->pool_keys);

        my $loaded = 0;
        for my $proxy (values $self->font_proxies->%*) {
            $loaded++ if $proxy->is_loaded;
        }
        say "遅延ロード済み: $loaded種類";
    }
}

# ===== メイン処理 =====

package main;

say "=" x 60;
say " ASCIIアート・フォントレンダラー v1.0 (完成版)";
say " Singleton × Flyweight × Proxy";
say "=" x 60;
say "";

# 起動時間を計測
my $start = time();

# Singleton: 設定マネージャーを初期化
my $manager = FontManager->instance;
$manager->font_path('/usr/share/fonts/ascii/standard.fnt');
$manager->default_style('bold');
$manager->char_spacing(1);

# レンダラーを作成
my $renderer = ASCIIArtRenderer->new;

my $init_time = time() - $start;
say sprintf("初期化時間: %.4f秒（瞬時！）", $init_time);
say "";

# テキストをレンダリング
say "【 HELLO WORLD を表示 】";
say "";
say $renderer->render("HELLO");
say "";
say $renderer->render("WORLD");
say "";

# 統計情報
$renderer->show_stats;
say "";

# パターンの解説
say "=" x 60;
say " 使用したデザインパターン";
say "=" x 60;
say "";

say "【1】Singleton パターン (FontManager)";
say "   └─ 設定を一元管理";
say "   └─ どこからでも FontManager->instance でアクセス";
say "   └─ 設定変更は1箇所でOK";
say "";

say "【2】Flyweight パターン (GlyphFactory + Glyph)";
say "   └─ 同じ文字のGlyphオブジェクトを共有";
say "   └─ 「HELLO」でも「L」は1つのオブジェクト";
say "   └─ メモリ使用量: 文字種類数に比例";
say "";

say "【3】Proxy パターン (FontProxy + RealFont)";
say "   └─ 実際のフォントデータを遅延ロード";
say "   └─ 使う文字だけオンデマンドでロード";
say "   └─ 起動時間とメモリを節約";
say "";

say "=" x 60;
say " 3パターンの連携";
say "=" x 60;
say "";
say <<'DIAGRAM';
    ┌─────────────────────────────────────────────────┐
    │              FontManager (Singleton)            │
    │  ┌─────────────────────────────────────────┐    │
    │  │ font_path: /usr/share/fonts/...        │    │
    │  │ default_style: bold                     │    │
    │  │ char_spacing: 1                         │    │
    │  └─────────────────────────────────────────┘    │
    └─────────────────────────────────────────────────┘
                          ↓ 設定を参照
    ┌─────────────────────────────────────────────────┐
    │           GlyphFactory (Flyweight Factory)      │
    │  ┌────────────────────────────────────────┐     │
    │  │  プール: { A: Glyph, H: Glyph, ... }  │     │
    │  │  同じ文字 → 同じオブジェクトを返す    │     │
    │  └────────────────────────────────────────┘     │
    └─────────────────────────────────────────────────┘
                          ↓ データが必要なとき
    ┌─────────────────────────────────────────────────┐
    │              FontProxy (Virtual Proxy)          │
    │  ┌────────────────────────────────────────┐     │
    │  │ 軽量なプロキシオブジェクト            │     │
    │  │ get_art() 呼び出し時に RealFont 生成  │     │
    │  └────────────────────────────────────────┘     │
    │                       ↓ 必要なときだけ          │
    │  ┌────────────────────────────────────────┐     │
    │  │ RealFont (重いフォントデータ)        │     │
    │  └────────────────────────────────────────┘     │
    └─────────────────────────────────────────────────┘
DIAGRAM

say "";
say "完成！3つのパターンが協力して動作しています。";
