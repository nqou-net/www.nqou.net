use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/06/weather_facade_cache.pl`;

like $output, qr/=== 天気予報アグリゲーター（キャッシュ付き） ===/, 'Header found';
like $output, qr/Toky.*（APIから）/, 'Tokyo initial fetch';
like $output, qr/Toky.*（キャッシュから）/, 'Tokyo cache fetch';
like $output, qr/ヒット率: 50.0%/, 'Hit rate check';

done_testing;
