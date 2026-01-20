#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, Storable（Perl標準モジュール）
#
# Storable::dclone()で深いコピーを実装
# ネストしたオブジェクトも完全に独立したコピーになる

use v5.36;
use Storable qw(dclone);

package Weapon {
    use Moo;

    has name  => (is => 'ro', required => 1);
    has power => (is => 'rw', required => 1);

    sub show ($self) {
        say "武器: " . $self->name . " (威力:" . $self->power . ")";
    }
}

package Monster {
    use Moo;
    use Storable qw(dclone);

    has name    => (is => 'ro', required => 1);
    has hp      => (is => 'rw', required => 1);
    has attack  => (is => 'rw', required => 1);
    has defense => (is => 'rw', required => 1);
    has weapon  => (is => 'rw');

    # 深いコピーを行うclone()メソッド
    sub clone ($self) {
        return dclone($self);
    }

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

# 武器を作成
my $fire_sword = Weapon->new(name => '炎の剣', power => 10);

# ドラゴンを作成
my $dragon1 = Monster->new(
    name    => 'ドラゴン',
    hp      => 100,
    attack  => 20,
    defense => 15,
    weapon  => $fire_sword,
);

# 深いコピーで複製
my $dragon2 = $dragon1->clone;

say "=== 変更前 ===";
$dragon1->show_status;
$dragon2->show_status;

# dragon2の武器の威力を変更
$dragon2->weapon->power(50);

say "\n=== dragon2の武器を変更した後 ===";
$dragon1->show_status;
$dragon2->show_status;

# 同一性の確認
say "\n=== 別々の武器オブジェクトか確認 ===";
say "同じオブジェクト: " . ($dragon1->weapon == $dragon2->weapon ? 'はい' : 'いいえ');
