use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/03/weather_adapter.pl`;

like $output, qr/=== 天気予報アグリゲーター（Adapter版） ===/, 'Header found';
like $output, qr/--- OpenWeatherMap ---/, 'OWM Section';
like $output, qr/Tokyo: 晴れ（気温 25.5℃、湿度 60%）/, 'OWM Tokyo';
like $output, qr/--- WeatherStack ---/, 'WS Section';
like $output, qr/Tokyo: Sunny（気温 26℃、湿度 58%）/, 'WS Tokyo';
like $output, qr/--- 統一インターフェースで扱う ---/, 'Unified Section';
# The order depends on how the loop runs, but Tokyo is printed twice.
like $output, qr/Tokyo: 25.5℃/, 'Unified Tokyo OWM';
like $output, qr/Tokyo: 26℃/, 'Unified Tokyo WS';

done_testing;
