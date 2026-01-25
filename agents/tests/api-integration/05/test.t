use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/05/weather_facade.pl`;

like $output, qr/=== 天気予報アグリゲーター（Facade版） ===/, 'Header found';
like $output, qr/Tokyo: 晴れ.*\[via OpenWeatherMap\]/, 'Tokyo via OWM';
like $output, qr/Sapporo: Rain.*\[via WeatherStack\]/, 'Sapporo via WeatherStack (fallback)';
like $output, qr/Fukuoka: データを取得できませんでした/, 'Fukuoka no data';
like $output, qr/Sapporo の天気データを WeatherStack から取得しました/, 'Manual check confirm';

done_testing;
