use v5.36;
use utf8;
use Test::More;

# before のスクリプトを直接 require
# (モジュール構成ではなく1ファイルスクリプトのため、出力をキャプチャしてテスト)

use Capture::Tiny qw(capture);
use FindBin;

my ($stdout, $stderr, $exit) = capture {
    do "$FindBin::Bin/../lib/RecipeManager.pm";
};

# 出力にレシピツリーが含まれること
like($stdout, qr/ビーフシチュー/,  'メインレシピが表示される');
like($stdout, qr/ルー作り/,     'サブレシピ（ルー作り）が表示される');
like($stdout, qr/デミグラスソース/, 'サブレシピ（デミグラスソース）が表示される');

# 材料合計の検証
like($stdout, qr/バター: 30g/,     'バターの量が正しい');
like($stdout, qr/薄力粉: 30g/,     '薄力粉の量が正しい');
like($stdout, qr/牛すね肉: 400g/,   '牛すね肉の量が正しい');
like($stdout, qr/玉ねぎ: 200g/,    '玉ねぎの量が正しい');
like($stdout, qr/にんじん: 150g/,   'にんじんの量が正しい');
like($stdout, qr/トマトペースト: 50g/, 'トマトペーストの量が正しい');
like($stdout, qr/赤ワイン: 100ml/,  '赤ワインの量が正しい');

done_testing;
