#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Mojo::DOM

use v5.36;
use Mojo::DOM;
use FindBin qw($RealBin);

# ローカルファイルを読み込む
my $file = "$RealBin/html/sample_news.html";
my $html = do {
    open my $fh, '<', $file or die "Cannot open $file: $!";
    local $/;
    <$fh>;
};

# Mojo::DOMオブジェクトを取得
my $dom = Mojo::DOM->new($html);

# CSSセレクタで見出しを全て取得
my $headlines = $dom->find('h2.headline');

say "=== ニュース見出し一覧 ===";
my $count = 1;
for my $headline ($headlines->each) {
    say "$count. " . $headline->text;
    $count++;
}
