#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Adapterパターンの完成形テスト

use_ok('WeatherService');
use_ok('OldWeatherAPI');
use_ok('OldWeatherAdapter');
use_ok('ForeignWeatherService');
use_ok('ForeignWeatherAdapter');

# パターンの構造テスト
subtest 'Adapterパターンの構成要素' => sub {
    # Target: WeatherServiceが提供する統一インターフェース
    my $target = WeatherService->new;
    can_ok($target, 'get_weather');
    can_ok($target, 'show_weather');
    
    # Adaptee1: OldWeatherAPI（既存のレガシーAPI）
    my $adaptee1 = OldWeatherAPI->new;
    can_ok($adaptee1, 'fetch_weather_info');
    ok(!$adaptee1->can('get_weather'), 'AdapteeはTargetインターフェースを持たない');
    
    # Adapter1: OldWeatherAdapter（橋渡しクラス）
    my $adapter1 = OldWeatherAdapter->new(old_api => $adaptee1);
    can_ok($adapter1, 'get_weather');    # Targetインターフェースを実装
    can_ok($adapter1, 'show_weather');   # Targetインターフェースを実装
    
    # Adaptee2: ForeignWeatherService（海外API）
    my $adaptee2 = ForeignWeatherService->new;
    can_ok($adaptee2, 'retrieve_conditions');
    ok(!$adaptee2->can('get_weather'), 'AdapteeはTargetインターフェースを持たない');
    
    # Adapter2: ForeignWeatherAdapter（橋渡しクラス）
    my $adapter2 = ForeignWeatherAdapter->new(foreign_service => $adaptee2);
    can_ok($adapter2, 'get_weather');    # Targetインターフェースを実装
    can_ok($adapter2, 'show_weather');   # Targetインターフェースを実装
};

# 委譲（delegation）のテスト
subtest '委譲による処理の転送' => sub {
    my $old_api = OldWeatherAPI->new;
    my $adapter = OldWeatherAdapter->new(old_api => $old_api);
    
    # Adapterが内部でAdapteeを保持している
    isa_ok($adapter->old_api, 'OldWeatherAPI');
    
    # Adapterの呼び出しがAdapteeに転送される
    my $direct_result = $old_api->fetch_weather_info('東京');
    is($direct_result, '晴れ/25度', 'Adapteeを直接呼ぶと文字列が返る');
    
    my $adapted_result = $adapter->get_weather('東京');
    is_deeply(
        $adapted_result,
        { condition => '晴れ', temperature => 25 },
        'Adapterを通すとハッシュリファレンスに変換される'
    );
};

# ラッピング（wrapping）のテスト
subtest 'インターフェースのラッピング' => sub {
    my $foreign = ForeignWeatherService->new;
    my $adapter = ForeignWeatherAdapter->new(foreign_service => $foreign);
    
    # Adapteeは配列リファレンスと英語の天気を返す
    my $direct_result = $foreign->retrieve_conditions('NYC');
    is_deeply($direct_result, ['Sunny', 20], 'Adapteeは配列リファレンスを返す');
    
    # Adapterはハッシュリファレンスと日本語の天気を返す
    my $adapted_result = $adapter->get_weather('ニューヨーク');
    is_deeply(
        $adapted_result,
        { condition => '晴れ', temperature => 20 },
        'Adapterは形式を変換する'
    );
};

# 多態性（polymorphism）のテスト
subtest '多態性による統一的な処理' => sub {
    my @services = (
        WeatherService->new,
        OldWeatherAdapter->new(old_api => OldWeatherAPI->new),
        ForeignWeatherAdapter->new(foreign_service => ForeignWeatherService->new),
    );
    
    # 各サービスに適した都市名を定義
    my %service_cities = (
        '国内天気サービス' => '東京',
        'レガシー天気API'  => '東京',
        '海外天気サービス' => 'ニューヨーク',
    );
    
    # すべてのサービスを同じループで処理できる
    for my $service (@services) {
        my $service_name = $service->name;
        my $test_city = $service_cities{$service_name} // '東京';
        
        ok($service->can('get_weather'), "$service_name: get_weatherを持つ");
        ok($service->can('show_weather'), "$service_name: show_weatherを持つ");
        
        # すべてのサービスが同じ形式の戻り値を返す（適切な都市名でテスト）
        my $result = $service->get_weather($test_city);
        is(ref($result), 'HASH', "$service_name: ハッシュリファレンスを返す");
        ok(exists $result->{condition}, "$service_name: conditionキーを持つ");
        ok(exists $result->{temperature}, "$service_name: temperatureキーを持つ");
        
        # 実際の天気データが取得できていることを確認（fallbackではない）
        isnt($result->{condition}, '不明', "$service_name: 実際の天気データを返す");
    }
};

# Adapterパターンのメリットのテスト
subtest 'Adapterパターンのメリット' => sub {
    # メリット1: 既存コードを変更しない
    my $old_api = OldWeatherAPI->new;
    ok($old_api->can('fetch_weather_info'), '既存APIはそのまま使える');
    ok(!$old_api->can('get_weather'), '既存APIは変更されていない');
    
    # メリット2: 単一責任の原則
    my $adapter = OldWeatherAdapter->new(old_api => $old_api);
    # Adapterは変換のみを担当
    ok($adapter->can('get_weather'), 'Adapterは変換インターフェースを提供');
    isa_ok($adapter->old_api, 'OldWeatherAPI', 'Adapterは元のオブジェクトを保持');
    
    # メリット3: 開放閉鎖の原則（新しいサービス追加時に既存コードを変更しない）
    my @services = (
        WeatherService->new,
        OldWeatherAdapter->new(old_api => $old_api),
    );
    
    # 新しいサービスを追加（既存のコードは変更しない）
    push @services, ForeignWeatherAdapter->new(
        foreign_service => ForeignWeatherService->new
    );
    
    # すべてのサービスが統一インターフェースで動作する
    is(scalar(@services), 3, '新しいサービスを簡単に追加できる');
};

done_testing();
