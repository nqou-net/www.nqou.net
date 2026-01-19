package WeatherScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use v5.36;
use Moo;
use experimental qw(signatures);

# WebScraperクラスを継承
extends 'WebScraper';

# extract_dataメソッドをオーバーライド
sub extract_data ($self, $dom) {
    my @forecasts;
    
    # tr.day-forecastから天気予報を抽出
    for my $row ($dom->find('tr.day-forecast')->each) {
        my $date = $row->at('td.date')->text;
        my $weather = $row->at('td.weather')->text;
        my $temp = $row->at('td.temp')->text;
        push @forecasts, {
            date    => $date,
            weather => $weather,
            temp    => $temp,
        };
    }
    
    return @forecasts;
}

# save_dataメソッドをオーバーライド
sub save_data ($self, @data) {
    say "=== 週間天気予報 ===";
    for my $forecast (@data) {
        say "$forecast->{date}: $forecast->{weather} ($forecast->{temp})";
    }
}

1;
