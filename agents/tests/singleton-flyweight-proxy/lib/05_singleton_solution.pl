#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use FontManager;

# 第5回: Singletonパターンで設定を一元管理

say "=== ASCIIアート・フォントレンダラー v0.5 (Singleton版) ===";
say "";

# どこからでも同じインスタンスにアクセス
my $manager = FontManager->instance;
$manager->show_config;
say "";

# 設定変更のデモ
say "*** 設定を変更してみましょう ***";
say "";
say "フォントパスを変更:";
$manager->font_path('/home/user/fonts/fancy.fnt');
say "  → " . $manager->font_path;
say "";

# 別の場所から同じインスタンスにアクセス
say "別の関数からアクセスしても同じ設定が見える:";
show_config_from_another_function();
say "";

# 改善効果を示す
say "*** 改善効果 ***";
say "";
say "FontManager->instance で常に同じオブジェクトを取得:";
say "  - 設定の変更は1箇所でOK";
say "  - どこからでも同じ設定にアクセス可能";
say "  - 設定の整合性が保証される";
say "";
say "→ 5箇所のハードコード → 1箇所の設定で解決！";

sub show_config_from_another_function {
    my $m = FontManager->instance;    # 同じインスタンス
    say "  フォントパス: " . $m->font_path;
    say "  スタイル: " . $m->default_style;
}
