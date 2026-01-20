#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# WeatherServiceクラスのテスト

use_ok('WeatherService');

# インスタンス生成のテスト
my $service = WeatherService->new;
isa_ok($service, 'WeatherService');

# get_weather メソッドのテスト - 東京
{
    my $weather = $service->get_weather('東京');
    is_deeply(
        $weather,
        { condition => '晴れ', temperature => 25 },
        '東京の天気情報を正しく取得できる'
    );
}

# get_weather メソッドのテスト - 大阪
{
    my $weather = $service->get_weather('大阪');
    is_deeply(
        $weather,
        { condition => '曇り', temperature => 23 },
        '大阪の天気情報を正しく取得できる'
    );
}

# get_weather メソッドのテスト - 札幌
{
    my $weather = $service->get_weather('札幌');
    is_deeply(
        $weather,
        { condition => '雨', temperature => 18 },
        '札幌の天気情報を正しく取得できる'
    );
}

# get_weather メソッドのテスト - 未登録の都市
{
    my $weather = $service->get_weather('福岡');
    is_deeply(
        $weather,
        { condition => '不明', temperature => 0 },
        '未登録の都市はデフォルト値を返す'
    );
}

# show_weather メソッドのテスト（正常に動作することを確認）
{
    my $output = '';
    eval {
        open my $fh, '>:utf8', \$output or die "Cannot open string: $!";
        local *STDOUT = $fh;
        $service->show_weather('東京');
    };
    is($@, '', 'show_weatherがエラーなく実行できる');
    ok(length($output) > 0, 'show_weatherが何らかの出力を生成する');
}

done_testing();
