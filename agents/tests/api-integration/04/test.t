use v5.36;
use Test::More;

my $output = `perl agents/tests/api-integration/04/problem_demonstration.pl`;

like $output, qr/=== 現状の問題点 ===/, 'Header found';
like $output, qr/Tokyo: 晴れ（気温 25.5℃）/, 'Tokyo weather output';
like $output, qr/--- 理想的な呼び出し方 ---/, 'Ideal way section';

done_testing;
