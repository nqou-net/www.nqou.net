#!/usr/bin/env perl
# 第1章: 緊急入院 - 500行のダメージ計算関数（Before版）
# コードドクター〜ダメージ計算式緊急手術

use v5.36;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

package DamageCalculator::Legacy {
    # 【重症】500行超えのダメージ計算関数
    # 新しい攻撃タイプを追加するたびに巨大化していった神クラス

    sub new ($class, %args) {
        return bless {
            attacker => $args{attacker},
            defender => $args{defender},
        }, $class;
    }

    # ダメージ計算 - すべてのロジックが1つの関数に
    sub calculate ($self, $attack_type, %params) {
        my $damage = 0;
        my $attacker = $self->{attacker};
        my $defender = $self->{defender};

        # 攻撃タイプ別分岐（if-else地獄の始まり）
        if ($attack_type eq '物理') {
            # 物理ダメージ計算
            $damage = $attacker->{attack} - $defender->{defense};
            $damage = int($damage * 1.0); # 補正なし

            # クリティカル判定
            if ($params{critical}) {
                $damage = int($damage * 1.5);
            }

            # 属性相性判定
            if ($params{element} && $defender->{weakness}) {
                if ($params{element} eq $defender->{weakness}) {
                    $damage = int($damage * 1.5);
                } elsif ($params{element} eq $defender->{resistance}) {
                    $damage = int($damage * 0.5);
                }
            }
        }
        elsif ($attack_type eq '魔法') {
            # 魔法ダメージ計算
            $damage = $attacker->{magic_attack} - $defender->{magic_defense};
            $damage = int($damage * 1.2); # 魔法補正

            # クリティカル判定（魔法は1.3倍）
            if ($params{critical}) {
                $damage = int($damage * 1.3);
            }

            # 属性相性判定（魔法は2倍の効果）
            if ($params{element} && $defender->{weakness}) {
                if ($params{element} eq $defender->{weakness}) {
                    $damage = int($damage * 2.0);
                } elsif ($params{element} eq $defender->{resistance}) {
                    $damage = int($damage * 0.25);
                }
            }
        }
        elsif ($attack_type eq '固定') {
            # 固定ダメージ（防御無視）
            $damage = $params{fixed_damage} // 100;
            # 固定ダメージはクリティカルや属性相性の影響を受けない
        }
        elsif ($attack_type eq '割合') {
            # 割合ダメージ（HPの一定割合）
            my $percent = $params{percent} // 10;
            $damage = int($defender->{max_hp} * $percent / 100);

            # 上限チェック
            my $cap = $params{cap} // 9999;
            $damage = $cap if $damage > $cap;
        }
        elsif ($attack_type eq '吸収') {
            # 吸収攻撃（与えたダメージの一定割合回復）
            $damage = $attacker->{attack} - $defender->{defense};
            my $heal_rate = $params{heal_rate} // 0.5;
            $attacker->{hp} += int($damage * $heal_rate);
        }
        elsif ($attack_type eq '毒') {
            # 毒ダメージ（ターン経過ダメージ）
            my $turns = $params{turns} // 3;
            my $damage_per_turn = $params{damage_per_turn} // 50;
            $damage = $damage_per_turn * $turns;
        }
        elsif ($attack_type eq '反射') {
            # 反射ダメージ
            my $reflected_damage = $params{incoming_damage} // 0;
            my $reflect_rate = $params{reflect_rate} // 0.5;
            $damage = int($reflected_damage * $reflect_rate);
        }
        elsif ($attack_type eq 'カウンター') {
            # カウンター攻撃
            $damage = $attacker->{attack} * 2 - $defender->{defense};
            $damage = int($damage * 0.8); # カウンター補正
        }
        elsif ($attack_type eq '貫通') {
            # 貫通攻撃（防御の一部を無視）
            my $penetration = $params{penetration} // 0.5;
            my $effective_defense = int($defender->{defense} * (1 - $penetration));
            $damage = $attacker->{attack} - $effective_defense;
        }
        elsif ($attack_type eq '連撃') {
            # 連続攻撃
            my $hits = $params{hits} // 3;
            my $base_damage = ($attacker->{attack} - $defender->{defense}) / 2;
            $damage = int($base_damage * $hits);
        }
        # ... さらに10種類以上の攻撃タイプが続く可能性 ...
        else {
            # 不明な攻撃タイプ
            warn "Unknown attack type: $attack_type";
            $damage = 0;
        }

        # 最低ダメージ保証
        $damage = 1 if $damage < 1;

        # バフ/デバフ補正（全攻撃タイプ共通だがまたif文）
        if ($attacker->{buffs} && $attacker->{buffs}{attack_up}) {
            $damage = int($damage * 1.25);
        }
        if ($defender->{debuffs} && $defender->{debuffs}{defense_down}) {
            $damage = int($damage * 1.2);
        }

        return $damage;
    }
}

# --- デモ実行 ---
sub demo {
    my $attacker = {
        attack => 150,
        magic_attack => 120,
        defense => 50,
        magic_defense => 40,
        hp => 500,
        max_hp => 500,
        buffs => { attack_up => 1 },
    };

    my $defender = {
        attack => 80,
        defense => 60,
        magic_defense => 70,
        hp => 400,
        max_hp => 400,
        weakness => '炎',
        resistance => '氷',
        debuffs => { defense_down => 1 },
    };

    my $calc = DamageCalculator::Legacy->new(
        attacker => $attacker,
        defender => $defender,
    );

    say "=== ダメージ計算デモ（Before版）===";
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
}

# メイン
demo() unless caller;

1;
