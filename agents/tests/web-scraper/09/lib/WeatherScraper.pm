package WeatherScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use v5.36;
use Moo;
use experimental qw(signatures);

extends 'WebScraper';

sub extract_data ($self, $dom) {
    my @forecasts;
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

sub save_data ($self, @data) {
    say "┌─────────────────────────────────┐";
    say "│       週間天気予報              │";
    say "├─────────┬────────┬──────────────┤";
    say "│ 日付    │ 天気   │ 気温         │";
    say "├─────────┼────────┼──────────────┤";
    for my $f (@data) {
        printf "│ %-7s │ %-6s │ %-12s │\n",
            $f->{date}, $f->{weather}, $f->{temp};
    }
    say "└─────────┴────────┴──────────────┘";
}

1;
