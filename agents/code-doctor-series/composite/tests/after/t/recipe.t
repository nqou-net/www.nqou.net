use v5.36;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use RecipeComponent;
use Ingredient;
use Recipe;

# --- Leaf (Ingredient) のテスト ---
subtest 'Ingredient basics' => sub {
    my $butter = Ingredient->new(name => 'バター', quantity => 30, unit => 'g');
    is $butter->name,     'バター', '名前が正しい';
    is $butter->quantity, 30,    '量が正しい';
    is $butter->unit,     'g',   '単位が正しい';

    my $result = $butter->calculate;
    is_deeply $result, {'バター' => {quantity => 30, unit => 'g'}}, 'calculateが自身の情報を返す';
};

# --- Composite (Recipe) のテスト ---
subtest 'Recipe with ingredients' => sub {
    my $roux = Recipe->new(name => 'ルー作り');
    $roux->add(Ingredient->new(name => 'バター', quantity => 30, unit => 'g'));
    $roux->add(Ingredient->new(name => '薄力粉', quantity => 30, unit => 'g'));

    my $result = $roux->calculate;
    is $result->{'バター'}{quantity}, 30, 'ルーのバター量';
    is $result->{'薄力粉'}{quantity}, 30, 'ルーの薄力粉量';
};

# --- ネストしたComposite のテスト ---
subtest 'Nested recipe tree' => sub {

    # ルー作り（サブレシピ）
    my $roux = Recipe->new(name => 'ルー作り');
    $roux->add(Ingredient->new(name => 'バター', quantity => 30, unit => 'g'));
    $roux->add(Ingredient->new(name => '薄力粉', quantity => 30, unit => 'g'));

    # デミグラスソース（サブレシピ）
    my $demiglace = Recipe->new(name => 'デミグラスソース');
    $demiglace->add(Ingredient->new(name => 'トマトペースト', quantity => 50,  unit => 'g'));
    $demiglace->add(Ingredient->new(name => '赤ワイン',    quantity => 100, unit => 'ml'));

    # ビーフシチュー（メイン）
    my $stew = Recipe->new(name => 'ビーフシチュー');
    $stew->add($roux);
    $stew->add($demiglace);
    $stew->add(Ingredient->new(name => '牛すね肉', quantity => 400, unit => 'g'));
    $stew->add(Ingredient->new(name => '玉ねぎ',  quantity => 200, unit => 'g'));
    $stew->add(Ingredient->new(name => 'にんじん', quantity => 150, unit => 'g'));

    # 全材料の集計
    my $totals = $stew->calculate;

    is $totals->{'バター'}{quantity},     30,  'バター 30g';
    is $totals->{'薄力粉'}{quantity},     30,  '薄力粉 30g';
    is $totals->{'トマトペースト'}{quantity}, 50,  'トマトペースト 50g';
    is $totals->{'赤ワイン'}{quantity},    100, '赤ワイン 100ml';
    is $totals->{'牛すね肉'}{quantity},    400, '牛すね肉 400g';
    is $totals->{'玉ねぎ'}{quantity},     200, '玉ねぎ 200g';
    is $totals->{'にんじん'}{quantity},    150, 'にんじん 150g';

    is scalar(keys %$totals), 7, '全7種類の材料';
};

# --- サブレシピの後追加テスト ---
subtest 'Adding sub-recipe later' => sub {
    my $stew = Recipe->new(name => 'ビーフシチュー');
    $stew->add(Ingredient->new(name => '牛すね肉', quantity => 400, unit => 'g'));

    my $totals_before = $stew->calculate;
    is scalar(keys %$totals_before), 1, '追加前は1材料';

    # 後からサブレシピを追加（コード変更不要！）
    my $roux = Recipe->new(name => 'ルー作り');
    $roux->add(Ingredient->new(name => 'バター', quantity => 30, unit => 'g'));
    $stew->add($roux);

    my $totals_after = $stew->calculate;
    is scalar(keys %$totals_after),      2,  '追加後は2材料';
    is $totals_after->{'バター'}{quantity}, 30, '追加されたバターの量が正しい';
};

# --- ツリー構造の検証 ---
subtest 'tree structure' => sub {
    my $stew = Recipe->new(name => 'ビーフシチュー');
    my $roux = Recipe->new(name => 'ルー作り');
    $roux->add(Ingredient->new(name => 'バター', quantity => 30, unit => 'g'));
    $stew->add($roux);
    $stew->add(Ingredient->new(name => '牛すね肉', quantity => 400, unit => 'g'));

    # display はツリー表示（目視確認用）。ここでは構造的にテスト
    is $stew->name, 'ビーフシチュー', 'メインレシピ名';
    my $children = $stew->{children};
    is scalar @$children, 2, '子要素は2つ（サブレシピ+材料）';
    isa_ok $children->[0], 'Recipe',     '1つ目はRecipe';
    isa_ok $children->[1], 'Ingredient', '2つ目はIngredient';
    is $children->[0]->name, 'ルー作り', 'サブレシピ名';
    is $children->[1]->name, '牛すね肉', '材料名';
};

done_testing;
