#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Adapterパターンのテスト

use_ok('WeatherService');
use_ok('OldWeatherAPI');
use_ok('OldWeatherAdapter');

# OldWeatherAdapterのインスタンス生成
{
    my $old_api = OldWeatherAPI->new;
    my $adapter = OldWeatherAdapter->new(old_api => $old_api);
    
    isa_ok($adapter, 'OldWeatherAdapter');
    can_ok($adapter, 'get_weather');
    can_ok($adapter, 'show_weather');
}

# Adapterが正しく変換しているかのテスト
{
    my $old_api = OldWeatherAPI->new;
    my $adapter = OldWeatherAdapter->new(old_api => $old_api);
    
    # 東京の天気
    my $weather = $adapter->get_weather('東京');
    is_deeply(
        $weather,
        { condition => '晴れ', temperature => 25 },
        'Adapter: 東京の天気を正しく変換'
    );
    
    # 名古屋の天気
    $weather = $adapter->get_weather('名古屋');
    is_deeply(
        $weather,
        { condition => '晴れ', temperature => 26 },
        'Adapter: 名古屋の天気を正しく変換'
    );
    
    # 未登録の都市
    $weather = $adapter->get_weather('福岡');
    is_deeply(
        $weather,
        { condition => '不明', temperature => 0 },
        'Adapter: 未登録の都市のデフォルト値'
    );
}

# WeatherServiceとOldWeatherAdapterが同じインターフェースを持つことを確認
{
    my $service = WeatherService->new;
    my $adapter = OldWeatherAdapter->new(old_api => OldWeatherAPI->new);
    
    # 両方ともget_weatherメソッドを持つ
    can_ok($service, 'get_weather');
    can_ok($adapter, 'get_weather');
    
    # 両方ともshow_weatherメソッドを持つ
    can_ok($service, 'show_weather');
    can_ok($adapter, 'show_weather');
    
    # 両方とも同じ形式の戻り値を返す
    my $weather1 = $service->get_weather('東京');
    my $weather2 = $adapter->get_weather('東京');
    
    is(ref($weather1), 'HASH', 'WeatherServiceはハッシュリファレンスを返す');
    is(ref($weather2), 'HASH', 'OldWeatherAdapterもハッシュリファレンスを返す');
    
    # 両方とも同じキーを持つ
    ok(exists $weather1->{condition}, 'WeatherServiceは condition キーを持つ');
    ok(exists $weather1->{temperature}, 'WeatherServiceは temperature キーを持つ');
    ok(exists $weather2->{condition}, 'OldWeatherAdapterも condition キーを持つ');
    ok(exists $weather2->{temperature}, 'OldWeatherAdapterも temperature キーを持つ');
}

done_testing();
