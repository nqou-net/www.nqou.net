#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
#
# 問題: 10体のスライムを作るのにコードが冗長
# 次回: clone()メソッドを使って効率的に量産する方法を学ぶ

use v5.36;

package Monster {
    use Moo;

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

# 10体のスライムを量産（冗長なコード）
my @slimes;
for (1..10) {
    push @slimes, Monster->new(
        name    => 'スライム',
        hp      => 10,
        attack  => 3,
        defense => 2,
    );
}

say "=== スライム軍団 ===";
for my $slime (@slimes) {
    $slime->show_status;
}
