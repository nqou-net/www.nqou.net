use v5.36;
use utf8;

# ============================================================
# レシピ管理アプリ — Before (骨格溶解型フラット化症候群)
#
# 全レシピ・材料をフラットな配列で管理。
# parent_id で親子関係を表現し、毎回ループで再構築。
# ref() チェックで材料とサブレシピを分岐。
# ============================================================

# --- フラットなデータ構造（全部ごちゃ混ぜ） ---
my @recipes = (
    # メインレシピ
    {
        id        => 1,
        parent_id => undef,
        type      => 'recipe',
        name      => 'ビーフシチュー',
    },
    # サブレシピ: ルー作り
    {
        id        => 2,
        parent_id => 1,
        type      => 'recipe',
        name      => 'ルー作り',
    },
    # ルー作りの材料
    {
        id        => 3,
        parent_id => 2,
        type      => 'ingredient',
        name      => 'バター',
        quantity  => 30,
        unit      => 'g',
    },
    {
        id        => 4,
        parent_id => 2,
        type      => 'ingredient',
        name      => '薄力粉',
        quantity  => 30,
        unit      => 'g',
    },
    # ビーフシチュー直下の材料
    {
        id        => 5,
        parent_id => 1,
        type      => 'ingredient',
        name      => '牛すね肉',
        quantity  => 400,
        unit      => 'g',
    },
    {
        id        => 6,
        parent_id => 1,
        type      => 'ingredient',
        name      => '玉ねぎ',
        quantity  => 200,
        unit      => 'g',
    },
    {
        id        => 7,
        parent_id => 1,
        type      => 'ingredient',
        name      => 'にんじん',
        quantity  => 150,
        unit      => 'g',
    },
    # サブレシピ: デミグラスソース
    {
        id        => 8,
        parent_id => 1,
        type      => 'recipe',
        name      => 'デミグラスソース',
    },
    {
        id        => 9,
        parent_id => 8,
        type      => 'ingredient',
        name      => 'トマトペースト',
        quantity  => 50,
        unit      => 'g',
    },
    {
        id        => 10,
        parent_id => 8,
        type      => 'ingredient',
        name      => '赤ワイン',
        quantity  => 100,
        unit      => 'ml',
    },
);

# --- 材料集計：毎回フラット配列からツリーを再構築 ---
# 正直、ここを触るのが怖い。3階層になってから動かなくなった。
sub calculate_total_ingredients ($recipe_id) {
    my %totals;

    for my $item (@recipes) {
        # 直下の子を探す
        next unless defined $item->{parent_id};
        next unless $item->{parent_id} == $recipe_id;

        if ($item->{type} eq 'ingredient') {
            # 材料ならそのまま加算
            my $key = $item->{name};
            $totals{$key} //= { quantity => 0, unit => $item->{unit} };
            $totals{$key}{quantity} += $item->{quantity};
        }
        elsif ($item->{type} eq 'recipe') {
            # サブレシピなら再帰的に……いや、ループで探す
            # TODO: 3階層以上で壊れるかも？ → 壊れた
            my $sub_totals = calculate_total_ingredients($item->{id});
            for my $name (keys %$sub_totals) {
                $totals{$name} //= { quantity => 0, unit => $sub_totals->{$name}{unit} };
                $totals{$name}{quantity} += $sub_totals->{$name}{quantity};
            }
        }
        # else: 未知のtypeは無視（たぶん大丈夫……）
    }

    return \%totals;
}

# --- 表示も毎回ツリーを再構築 ---
sub display_recipe ($recipe_id, $indent = 0) {
    my $prefix = '  ' x $indent;

    for my $item (@recipes) {
        next unless defined $item->{parent_id};
        next unless $item->{parent_id} == $recipe_id;

        if ($item->{type} eq 'recipe') {
            say "${prefix}[$item->{name}]";
            display_recipe($item->{id}, $indent + 1);
        }
        elsif ($item->{type} eq 'ingredient') {
            say "${prefix}$item->{name}: $item->{quantity}$item->{unit}";
        }
    }
}

# --- 実行 ---
say '=== ビーフシチュー レシピツリー ===';
say '[ビーフシチュー]';
display_recipe(1);

say '';
say '=== 材料合計 ===';
my $totals = calculate_total_ingredients(1);
for my $name (sort keys %$totals) {
    say "$name: $totals->{$name}{quantity}$totals->{$name}{unit}";
}
