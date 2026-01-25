use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/08/weather_cli.pl`;

like $output, qr/天気予報アグリゲーター（完成版）/, 'Header found';
like $output, qr/\[天気情報\]/, 'Weather info section';
like $output, qr/Unknown.*\[デフォルト\]/, 'Unknown city default';
like $output, qr/\[2回目の取得（キャッシュから）\]/, 'Cache section';
like $output, qr/Tokyo: キャッシュから/, 'Tokyo cached';
like $output, qr/ヒット率:         30.0%/, 'Hit rate check';

done_testing;
