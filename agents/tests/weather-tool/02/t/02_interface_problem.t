#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# WeatherServiceとOldWeatherAPIのテスト

use_ok('WeatherService');
use_ok('OldWeatherAPI');

# WeatherServiceのテスト
{
    my $service = WeatherService->new;
    isa_ok($service, 'WeatherService');
    
    my $weather = $service->get_weather('東京');
    is_deeply(
        $weather,
        { condition => '晴れ', temperature => 25 },
        'WeatherService: 東京の天気情報'
    );
}

# OldWeatherAPIのテスト
{
    my $api = OldWeatherAPI->new;
    isa_ok($api, 'OldWeatherAPI');
    
    my $info = $api->fetch_weather_info('東京');
    is($info, '晴れ/25度', 'OldWeatherAPI: 東京の天気情報（文字列形式）');
    
    $info = $api->fetch_weather_info('名古屋');
    is($info, '晴れ/26度', 'OldWeatherAPI: 名古屋の天気情報（文字列形式）');
    
    $info = $api->fetch_weather_info('福岡');
    is($info, '情報なし', 'OldWeatherAPI: 未登録の都市');
}

# インターフェースの違いを確認
{
    my $service = WeatherService->new;
    my $api = OldWeatherAPI->new;
    
    # WeatherServiceはget_weatherメソッドを持つ
    can_ok($service, 'get_weather');
    can_ok($service, 'show_weather');
    
    # OldWeatherAPIはfetch_weather_infoメソッドを持つ
    can_ok($api, 'fetch_weather_info');
    
    # OldWeatherAPIはget_weatherメソッドを持たない
    ok(!$api->can('get_weather'), 'OldWeatherAPIはget_weatherメソッドを持たない');
}

done_testing();
