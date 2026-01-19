#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use FindBin qw($RealBin);
use WebScraper;

# 直接WebScraperを使用すると、extract_dataが実装されていないのでエラーになる
my $scraper = WebScraper->new(url => "$RealBin/../01/html/sample_news.html");

eval {
    $scraper->scrape();
};

if ($@) {
    say "期待通りのエラー: $@";
    say "テスト成功: 抽象メソッドが正しく動作しています";
} else {
    die "テスト失敗: エラーが発生するはずでした";
}
