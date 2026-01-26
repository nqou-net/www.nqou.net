#!/usr/bin/env perl
use v5.36;

# OpenWeatherMap APIモック
sub get_openweathermap_data ($city) {
    my %mock_data = (
        'Tokyo' => {
            name => 'Tokyo',
            main => { temp => 25.5, humidity => 60 },
            weather => [{ description => '晴れ' }],
        },
    );
    return $mock_data{$city};
}

# WeatherStack APIモック
sub get_weatherstack_data ($city) {
    my %mock_data = (
        'Tokyo' => {
            location => { name => 'Tokyo' },
            current  => { temperature => 26, humidity => 58, weather_descriptions => ['Sunny'] },
        },
    );
    return $mock_data{$city};
}

# WeatherAPI APIモック（3つ目）
sub get_weatherapi_data ($city) {
    my %mock_data = (
        'Tokyo' => {
            location => { name => 'Tokyo' },
            current  => { 
                temp_c    => 25.8, 
                humidity  => 59, 
                condition => { text => 'Clear' },
            },
        },
    );
    return $mock_data{$city};
}

# 天気情報を表示（3つのAPIに対応）
sub show_weather ($city, $service) {
    if ($service eq 'openweathermap') {
        my $data = get_openweathermap_data($city);
        if ($data) {
            my $temp = $data->{main}{temp};
            my $humidity = $data->{main}{humidity};
            my $desc = $data->{weather}[0]{description};
            say "[$service] $city: $desc（気温 $temp℃、湿度 $humidity%）";
        }
    }
    elsif ($service eq 'weatherstack') {
        my $data = get_weatherstack_data($city);
        if ($data) {
            my $temp = $data->{current}{temperature};
            my $humidity = $data->{current}{humidity};
            my $desc = $data->{current}{weather_descriptions}[0];
            say "[$service] $city: $desc（気温 $temp℃、湿度 $humidity%）";
        }
    }
    elsif ($service eq 'weatherapi') {
        my $data = get_weatherapi_data($city);
        if ($data) {
            my $temp = $data->{current}{temp_c};           # temp_c !
            my $humidity = $data->{current}{humidity};
            my $desc = $data->{current}{condition}{text};  # condition.text !
            say "[$service] $city: $desc（気温 $temp℃、湿度 $humidity%）";
        }
    }
    else {
        say "不明なサービス: $service";
    }
}

# メイン処理
say "=== 天気予報アグリゲーター（3サービス対応） ===";
show_weather('Tokyo', 'openweathermap');
show_weather('Tokyo', 'weatherstack');
show_weather('Tokyo', 'weatherapi');
