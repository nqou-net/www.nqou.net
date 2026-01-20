#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, MooX::Clone（cpanmでインストール）
#
# clone()を使って10体のスライムを量産

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

# clone()で量産（たった1行！）
my @slimes = map { $base_slime->clone } 1..10;

say "=== スライム軍団（10体）===";
for my $slime (@slimes) {
    $slime->show_status;
}
