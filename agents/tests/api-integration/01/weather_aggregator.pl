#!/usr/bin/env perl
use v5.36;
use HTTP::Tiny;
use JSON::PP;

# OpenWeatherMap API呼び出し（モック版）
# 実際にAPIを使う場合は、HTTP::Tiny->get() でリクエストを送信
sub get_weather_from_openweathermap ($city) {
    # モックデータ（実際のAPIレスポンスを模した構造）
    my %mock_data = (
        'Tokyo' => {
            name => 'Tokyo',
            main => {
                temp     => 25.5,
                humidity => 60,
            },
            weather => [
                { description => '晴れ' },
            ],
        },
        'Osaka' => {
            name => 'Osaka',
            main => {
                temp     => 27.2,
                humidity => 65,
            },
            weather => [
                { description => '曇り' },
            ],
        },
        'Sapporo' => {
            name => 'Sapporo',
            main => {
                temp     => 18.3,
                humidity => 70,
            },
            weather => [
                { description => '雨' },
            ],
        },
    );

    return $mock_data{$city};
}

# 天気情報を整形して表示
sub show_weather ($city) {
    my $data = get_weather_from_openweathermap($city);
    
    if ($data) {
        my $temp        = $data->{main}{temp};
        my $humidity    = $data->{main}{humidity};
        my $description = $data->{weather}[0]{description};
        say "$city: $description（気温 $temp℃、湿度 $humidity%）";
    }
    else {
        say "$city: データを取得できませんでした";
    }
}

# メイン処理
say "=== 天気予報アグリゲーター ===";
say "";

my @cities = qw(Tokyo Osaka Sapporo Fukuoka);

for my $city (@cities) {
    show_weather($city);
}
