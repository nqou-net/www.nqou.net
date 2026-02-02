#!/usr/bin/env perl
# 第2-4章: Strategy パターン導入後（After版）
# コードドクター〜ダメージ計算式緊急手術

use v5.36;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

# =========================================
# ダメージ計算Strategy インターフェース
# =========================================
package DamageStrategy {

    sub new ($class, %args) {
        return bless \%args, $class;
    }

    # 抽象メソッド（サブクラスで実装）
    sub calculate ($self, $attacker, $defender, %params) {
        die "calculate() must be implemented by subclass";
    }

    sub name ($self) {
        die "name() must be implemented by subclass";
    }

    # 共通: 属性相性を計算
    sub element_modifier ($self, $element, $defender) {
        return 1.0 unless $element;
        return 1.0 unless $defender->{weakness} || $defender->{resistance};

        if ($element eq ($defender->{weakness} // '')) {
            return $self->{weakness_multiplier} // 1.5;
        }
        if ($element eq ($defender->{resistance} // '')) {
            return $self->{resistance_multiplier} // 0.5;
        }
        return 1.0;
    }

    # 共通: クリティカル倍率
    sub critical_modifier ($self, $is_critical) {
        return $is_critical
            ? ($self->{critical_multiplier} // 1.5)
            : 1.0;
    }

    # 共通: バフ/デバフ補正
    sub buff_modifier ($self, $attacker, $defender) {
        my $mod = 1.0;
        if ($attacker->{buffs} && $attacker->{buffs}{attack_up}) {
            $mod *= 1.25;
        }
        if ($defender->{debuffs} && $defender->{debuffs}{defense_down}) {
            $mod *= 1.2;
        }
        return $mod;
    }

    # 共通: 最低ダメージ保証
    sub ensure_minimum ($self, $damage) {
        return $damage < 1 ? 1 : int($damage);
    }
}

# =========================================
# 物理ダメージ Strategy
# =========================================
package PhysicalDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub new ($class) {
        return $class->SUPER::new(
            critical_multiplier   => 1.5,
            weakness_multiplier   => 1.5,
            resistance_multiplier => 0.5,
        );
    }

    sub name ($self) {'物理'}

    sub calculate ($self, $attacker, $defender, %params) {
        my $base = $attacker->{attack} - $defender->{defense};

        $base *= $self->critical_modifier($params{critical});
        $base *= $self->element_modifier($params{element}, $defender);
        $base *= $self->buff_modifier($attacker, $defender);

        return $self->ensure_minimum($base);
    }
}

# =========================================
# 魔法ダメージ Strategy
# =========================================
package MagicDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub new ($class) {
        return $class->SUPER::new(
            base_multiplier       => 1.2,
            critical_multiplier   => 1.3,
            weakness_multiplier   => 2.0,
            resistance_multiplier => 0.25,
        );
    }

    sub name ($self) {'魔法'}

    sub calculate ($self, $attacker, $defender, %params) {
        my $base = $attacker->{magic_attack} - $defender->{magic_defense};
        $base *= $self->{base_multiplier};

        $base *= $self->critical_modifier($params{critical});
        $base *= $self->element_modifier($params{element}, $defender);
        $base *= $self->buff_modifier($attacker, $defender);

        return $self->ensure_minimum($base);
    }
}

# =========================================
# 固定ダメージ Strategy
# =========================================
package FixedDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub name ($self) {'固定'}

    sub calculate ($self, $attacker, $defender, %params) {

        # 固定ダメージは防御・属性・クリティカルを無視
        my $damage = $params{fixed_damage} // 100;
        return $self->ensure_minimum($damage);
    }
}

# =========================================
# 割合ダメージ Strategy（第3章で追加）
# =========================================
package PercentDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub name ($self) {'割合'}

    sub calculate ($self, $attacker, $defender, %params) {
        my $percent = $params{percent} // 10;
        my $damage  = int($defender->{max_hp} * $percent / 100);

        # 上限チェック
        my $cap = $params{cap} // 9999;
        $damage = $cap if $damage > $cap;

        return $self->ensure_minimum($damage);
    }
}

# =========================================
# 貫通ダメージ Strategy（第3章で追加）
# =========================================
package PenetrationDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub new ($class) {
        return $class->SUPER::new(critical_multiplier => 1.5,);
    }

    sub name ($self) {'貫通'}

    sub calculate ($self, $attacker, $defender, %params) {
        my $penetration       = $params{penetration} // 0.5;
        my $effective_defense = int($defender->{defense} * (1 - $penetration));
        my $base              = $attacker->{attack} - $effective_defense;

        $base *= $self->critical_modifier($params{critical});
        $base *= $self->buff_modifier($attacker, $defender);

        return $self->ensure_minimum($base);
    }
}

# =========================================
# 連撃ダメージ Strategy（第3章で追加）
# =========================================
package MultiHitDamageStrategy {
    use parent -norequire, 'DamageStrategy';

    sub name ($self) {'連撃'}

    sub calculate ($self, $attacker, $defender, %params) {
        my $hits        = $params{hits} // 3;
        my $base_damage = ($attacker->{attack} - $defender->{defense}) / 2;
        my $damage      = int($base_damage * $hits);

        $damage *= $self->buff_modifier($attacker, $defender);

        return $self->ensure_minimum($damage);
    }
}

# =========================================
# ダメージ計算コンテキスト（統合クラス）
# =========================================
package DamageCalculator {

    sub new ($class, %args) {
        return bless {
            attacker   => $args{attacker},
            defender   => $args{defender},
            strategies => {},
        }, $class;
    }

    # Strategy を登録
    sub register_strategy ($self, $strategy) {
        my $name = $strategy->name;
        $self->{strategies}{$name} = $strategy;
        return $self;
    }

    # ダメージ計算
    sub calculate ($self, $attack_type, %params) {
        my $strategy = $self->{strategies}{$attack_type}
            or die "Unknown attack type: $attack_type";

        return $strategy->calculate($self->{attacker}, $self->{defender}, %params);
    }

    # 登録済みの攻撃タイプ一覧
    sub available_types ($self) {
        return sort keys %{$self->{strategies}};
    }
}

# =========================================
# StrategyFactory（第5章: Factory追加）
# =========================================
package DamageStrategyFactory {
    my %STRATEGIES = (
        '物理' => 'PhysicalDamageStrategy',
        '魔法' => 'MagicDamageStrategy',
        '固定' => 'FixedDamageStrategy',
        '割合' => 'PercentDamageStrategy',
        '貫通' => 'PenetrationDamageStrategy',
        '連撃' => 'MultiHitDamageStrategy',
    );

    sub create ($class, $type) {
        my $strategy_class = $STRATEGIES{$type}
            or die "Unknown strategy type: $type";
        return $strategy_class->new;
    }

    sub create_all ($class) {
        return map { $class->create($_) } keys %STRATEGIES;
    }

    sub available_types ($class) {
        return sort keys %STRATEGIES;
    }
}

# --- デモ実行 ---
sub demo {
    my $attacker = {
        attack        => 150,
        magic_attack  => 120,
        defense       => 50,
        magic_defense => 40,
        hp            => 500,
        max_hp        => 500,
        buffs         => {attack_up => 1},
    };

    my $defender = {
        attack        => 80,
        defense       => 60,
        magic_defense => 70,
        hp            => 400,
        max_hp        => 400,
        weakness      => '炎',
        resistance    => '氷',
        debuffs       => {defense_down => 1},
    };

    # Factory を使用してすべての Strategy を登録
    my $calc = DamageCalculator->new(
        attacker => $attacker,
        defender => $defender,
    );

    for my $strategy (DamageStrategyFactory->create_all) {
        $calc->register_strategy($strategy);
    }

    say "=== ダメージ計算デモ（After版: Strategy パターン）===";
    say "登録済み攻撃タイプ: ", join(', ', $calc->available_types);
    say "";

    # 物理攻撃
    my $phys = $calc->calculate('物理', critical => 0);
    say "物理ダメージ: $phys";

    # 物理攻撃（クリティカル）
    my $phys_crit = $calc->calculate('物理', critical => 1);
    say "物理クリティカル: $phys_crit";

    # 魔法攻撃（炎属性 → 弱点）
    my $magic = $calc->calculate('魔法', element => '炎');
    say "魔法ダメージ（炎→弱点）: $magic";

    # 固定ダメージ
    my $fixed = $calc->calculate('固定', fixed_damage => 200);
    say "固定ダメージ: $fixed";

    # 割合ダメージ（HP20%）
    my $percent = $calc->calculate('割合', percent => 20, cap => 500);
    say "割合ダメージ: $percent";

    # 貫通ダメージ（50%貫通）
    my $penetration = $calc->calculate('貫通', penetration => 0.5);
    say "貫通ダメージ: $penetration";

    # 連撃（5回）
    my $multi = $calc->calculate('連撃', hits => 5);
    say "連撃ダメージ: $multi";
}

# メイン
demo() unless caller;

1;
