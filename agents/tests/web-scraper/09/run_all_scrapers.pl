#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: NewsScraper, WeatherScraper, ProductScraper

use v5.36;
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use NewsScraper;
use WeatherScraper;
use ProductScraper;

say "=" x 50;
say "  Webスクレイパー統合システム";
say "=" x 50;
say "";

# スクレイパーの設定
my @scrapers = (
    {
        class => 'NewsScraper',
        url   => "$RealBin/../01/html/sample_news.html",
        name  => 'ニュース',
    },
    {
        class => 'WeatherScraper',
        url   => "$RealBin/../02/html/sample_weather.html",
        name  => '天気予報',
    },
    {
        class => 'ProductScraper',
        url   => "$RealBin/html/sample_products.html",
        name  => '商品情報',
    },
);

# 各スクレイパーを実行
for my $config (@scrapers) {
    say "【$config->{name}】";
    
    my $class = $config->{class};
    my $scraper = $class->new(url => $config->{url});
    
    eval {
        $scraper->scrape();
    };
    if ($@) {
        warn "エラーが発生しました: $@";
    }
    
    say "";
}

say "=" x 50;
say "  スクレイピング完了！";
say "=" x 50;
