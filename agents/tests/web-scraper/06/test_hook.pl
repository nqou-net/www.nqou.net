#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use FindBin qw($RealBin);
use NewsScraper;
use WeatherScraper;

# ニュースを画面出力
say "--- ニュース（画面出力）---";
my $news1 = NewsScraper->new(url => "file://$RealBin/../01/html/sample_news.html");
$news1->scrape();

say "";

# ニュースをファイル保存
say "--- ニュース（ファイル保存）---";
my $news2 = NewsScraper->new(
    url         => "file://$RealBin/../01/html/sample_news.html",
    output_file => "$RealBin/news.txt"
);
$news2->scrape();

say "";

# 天気（カスタム形式で画面出力）
say "--- 天気予報 ---";
my $weather = WeatherScraper->new(url => "file://$RealBin/../02/html/sample_weather.html");
$weather->scrape();
