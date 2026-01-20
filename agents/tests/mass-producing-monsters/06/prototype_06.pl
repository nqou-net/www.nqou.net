#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, Storable（Perl標準モジュール）

use v5.36;
use Storable qw(dclone);

# Prototypeロール（clone()を要求）
package Cloneable {
    use Moo::Role;
    requires 'clone';
}

package Weapon {
    use Moo;
    use Storable qw(dclone);
    with 'Cloneable';

    has name  => (is => 'ro', required => 1);
    has power => (is => 'rw', required => 1);

    sub clone ($self) {
        return dclone($self);
    }
}

package Monster {
    use Moo;
    use Storable qw(dclone);
    with 'Cloneable';

    has name    => (is => 'ro', required => 1);
    has hp      => (is => 'rw', required => 1);
    has attack  => (is => 'rw', required => 1);
    has defense => (is => 'rw', required => 1);
    has weapon  => (is => 'rw');

    sub clone ($self) {
        return dclone($self);
    }

    sub show_status ($self) {
        say "【" . $self->name . "】HP:" . $self->hp
            . " 攻撃:" . $self->attack
            . " 防御:" . $self->defense;
    }
}

# Prototypeパターンの利用例
my $base_weapon = Weapon->new(name => '炎の剣', power => 10);
my $base_monster = Monster->new(
    name    => 'スライム',
    hp      => 10,
    attack  => 3,
    defense => 2,
    weapon  => $base_weapon,
);

my $red_slime = $base_monster->clone;
$red_slime->weapon->power(15);
