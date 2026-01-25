use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/07/weather_facade_handling.pl 2>&1`; # Capture stderr as well

like $output, qr/=== 天気予報アグリゲーター（エラーハンドリング版） ===/, 'Header found';
like $output, qr/API connection timeout for Fukuoka/, 'Warn message captured';
like $output, qr/API rate limit exceeded for Fukuoka/, 'Warn message 2 captured';
like $output, qr/Fukuoka: 情報を取得できませんでした.*\[デフォルト\]/, 'Default value behavior';
like $output, qr/Fukuoka: データ取得に失敗しました（undefが返されました）/, 'Strict mode behavior';

done_testing;
