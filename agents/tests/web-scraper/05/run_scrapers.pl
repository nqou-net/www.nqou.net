#!/usr/bin/env perl
use v5.36;
use FindBin qw($RealBin);
use lib "$RealBin/lib";
use NewsScraper;
use WeatherScraper;

# パスを正規化
my $news_html = "$RealBin/../01/html/sample_news.html";
my $weather_html = "$RealBin/../02/html/sample_weather.html";

# ファイルが存在するか確認
die "ファイルが見つかりません: $news_html" unless -f $news_html;
die "ファイルが見つかりません: $weather_html" unless -f $weather_html;

# ニューススクレイパーを実行
my $news = NewsScraper->new(url => $news_html);
$news->scrape();

say "";

# 天気スクレイパーを実行
my $weather = WeatherScraper->new(url => $weather_html);
$weather->scrape();
