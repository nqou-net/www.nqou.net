#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, MooX::Clone（cpanmでインストール）

use v5.36;

# 武器クラス
package Weapon {
    use Moo;

    has name   => (is => 'ro', required => 1);
    has power  => (is => 'rw', required => 1);

    sub show ($self) {
        say "武器: " . $self->name . " (威力:" . $self->power . ")";
    }
}

# モンスタークラス（武器を装備可能）
package Monster {
    use Moo;
    use MooX::Clone;

    has name    => (is => 'ro', required => 1);
    has hp      => (is => 'rw', required => 1);
    has attack  => (is => 'rw', required => 1);
    has defense => (is => 'rw', required => 1);
    has weapon  => (is => 'rw');  # Weaponオブジェクトを持つ

    sub show_status ($self) {
        say "【" . $self->name . "】HP:" . $self->hp
            . " 攻撃:" . $self->attack
            . " 防御:" . $self->defense;
        if ($self->weapon) {
            $self->weapon->show;
        }
    }

    sub total_attack ($self) {
        my $base = $self->attack;
        my $weapon_power = $self->weapon ? $self->weapon->power : 0;
        return $base + $weapon_power;
    }
}

# 炎の剣を作成
my $fire_sword = Weapon->new(name => '炎の剣', power => 10);

# 炎の剣を装備したドラゴンを作成
my $dragon = Monster->new(
    name    => 'ドラゴン',
    hp      => 100,
    attack  => 20,
    defense => 15,
    weapon  => $fire_sword,
);

$dragon->show_status;
say "総攻撃力: " . $dragon->total_attack;

# ドラゴンを複製
my $dragon2 = $dragon->clone;

# dragon2の武器の威力を変更
$dragon2->weapon->power(20);

say "=== ドラゴン1 ===";
$dragon->show_status;
say "=== ドラゴン2 ===";
$dragon2->show_status;
