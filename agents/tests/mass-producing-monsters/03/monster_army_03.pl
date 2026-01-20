#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, MooX::Clone（cpanmでインストール）
#
# clone()でベースを複製し、属性を変更してバリエーションを作成

use v5.36;

package Monster {
    use Moo;
    use MooX::Clone;

    has name    => (is => 'ro', required => 1);
    has hp      => (is => 'rw', required => 1);
    has attack  => (is => 'rw', required => 1);
    has defense => (is => 'rw', required => 1);
    has color   => (is => 'rw', default => '緑');

    sub show_status ($self) {
        say "【" . $self->name . "】HP:" . $self->hp
            . " 攻撃:" . $self->attack
            . " 防御:" . $self->defense
            . " 色:" . $self->color;
    }
}

# ベーススライムを1体作成
my $base_slime = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
);

# 5色のスライム軍団を作成
my @colors = qw(緑 赤 青 金 銀);
my @color_slimes = map {
    my $slime = $base_slime->clone;
    $slime->color($_);
    $slime;
} @colors;

say "=== 5色スライム軍団 ===";
for my $slime (@color_slimes) {
    $slime->show_status;
}

# 強化版スライムも作成
say "\n=== 強化版スライム ===";
my $strong_slime = $base_slime->clone;
$strong_slime->hp(15);
$strong_slime->attack(5);
$strong_slime->defense(3);
$strong_slime->color('虹');
$strong_slime->show_status;
