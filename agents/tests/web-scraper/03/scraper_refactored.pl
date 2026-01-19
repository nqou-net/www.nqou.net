#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Mojo::UserAgent（Mojoliciousに含まれる）

use v5.36;
use Mojo::UserAgent;
use FindBin qw($RealBin);

# 共通の「取得」処理を関数化
sub fetch_html ($url) {
    my $ua = Mojo::UserAgent->new;
    my $res = $ua->get($url)->result;
    
    if ($res->is_success) {
        return $res->dom;
    }
    die "取得失敗: " . $res->message;
}

# 共通の「保存」処理（画面出力）
sub save_to_screen ($title, @data) {
    say "=== $title ===";
    for my $item (@data) {
        say "- $item";
    }
}

# ニュースを抽出（スクレイパー固有の処理）
sub extract_news ($dom) {
    my @headlines;
    for my $headline ($dom->find('h2.headline')->each) {
        push @headlines, $headline->text;
    }
    return @headlines;
}

# 天気を抽出（スクレイパー固有の処理）
sub extract_weather ($dom) {
    my @forecasts;
    for my $row ($dom->find('tr.day-forecast')->each) {
        my $date = $row->at('td.date')->text;
        my $weather = $row->at('td.weather')->text;
        push @forecasts, "$date: $weather";
    }
    return @forecasts;
}

# メイン処理
my $news_dom = fetch_html("file://$RealBin/../01/html/sample_news.html");
my @news = extract_news($news_dom);
save_to_screen("ニュース見出し一覧", @news);

say "";

my $weather_dom = fetch_html("file://$RealBin/../02/html/sample_weather.html");
my @weather = extract_weather($weather_dom);
save_to_screen("週間天気予報", @weather);
