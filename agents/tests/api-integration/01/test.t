use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/01/weather_aggregator.pl`;

like $output, qr/=== 天気予報アグリゲーター ===/, 'Header found';
like $output, qr/Tokyo: 晴れ（気温 25.5℃、湿度 60%）/, 'Tokyo weather match';
like $output, qr/Osaka: 曇り（気温 27.2℃、湿度 65%）/, 'Osaka weather match';
like $output, qr/Sapporo: 雨（気温 18.3℃、湿度 70%）/, 'Sapporo weather match';
like $output, qr/Fukuoka: データを取得できませんでした/, 'Fukuoka no data match';

done_testing;
