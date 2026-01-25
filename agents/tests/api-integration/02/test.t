use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/02/weather_aggregator_v2.pl`;

like $output, qr/=== 天気予報アグリゲーター（3サービス対応） ===/, 'Header found';
like $output, qr/\[openweathermap\] Tokyo: 晴れ（気温 25.5℃、湿度 60%）/, 'OpenWeatherMap match';
like $output, qr/\[weatherstack\] Tokyo: Sunny（気温 26℃、湿度 58%）/, 'WeatherStack match';
like $output, qr/\[weatherapi\] Tokyo: Clear（気温 25.8℃、湿度 59%）/, 'WeatherAPI match';

done_testing;
