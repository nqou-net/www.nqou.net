#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# 複数サービス統合のテスト

use_ok('WeatherService');
use_ok('OldWeatherAPI');
use_ok('OldWeatherAdapter');
use_ok('ForeignWeatherService');
use_ok('ForeignWeatherAdapter');

# 3つのサービスを準備
my @services = (
    WeatherService->new,
    OldWeatherAdapter->new(old_api => OldWeatherAPI->new),
    ForeignWeatherAdapter->new(foreign_service => ForeignWeatherService->new),
);

# 各サービスが正しく生成されているか
{
    isa_ok($services[0], 'WeatherService');
    isa_ok($services[1], 'OldWeatherAdapter');
    isa_ok($services[2], 'ForeignWeatherAdapter');
}

# すべてのサービスが統一インターフェースを持つか
{
    for my $service (@services) {
        can_ok($service, 'get_weather');
        can_ok($service, 'show_weather');
        can_ok($service, 'name');
    }
}

# 各サービスの名前を確認
{
    is($services[0]->name, '国内天気サービス', 'WeatherServiceの名前');
    is($services[1]->name, 'レガシー天気API', 'OldWeatherAdapterの名前');
    is($services[2]->name, '海外天気サービス', 'ForeignWeatherAdapterの名前');
}

# ForeignWeatherAdapterの動作確認
{
    my $adapter = $services[2];
    
    my $weather = $adapter->get_weather('ニューヨーク');
    is_deeply(
        $weather,
        { condition => '晴れ', temperature => 20 },
        'ForeignWeatherAdapter: ニューヨークの天気を正しく変換'
    );
    
    $weather = $adapter->get_weather('ロンドン');
    is_deeply(
        $weather,
        { condition => '曇り', temperature => 15 },
        'ForeignWeatherAdapter: ロンドンの天気を正しく変換'
    );
    
    $weather = $adapter->get_weather('パリ');
    is_deeply(
        $weather,
        { condition => '雨', temperature => 12 },
        'ForeignWeatherAdapter: パリの天気を正しく変換'
    );
}

# ループで統一的に処理できることを確認
{
    for my $service (@services) {
        my $weather = $service->get_weather('東京');  # すべてのサービスで呼び出せる
        ok(ref($weather) eq 'HASH', $service->name . 'はハッシュリファレンスを返す');
        ok(exists $weather->{condition}, $service->name . 'はconditionキーを持つ');
        ok(exists $weather->{temperature}, $service->name . 'はtemperatureキーを持つ');
    }
}

done_testing();
