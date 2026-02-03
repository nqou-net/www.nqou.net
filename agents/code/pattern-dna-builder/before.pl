#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# =============================================================================
# Before: コンストラクタ引数爆発症
# =============================================================================
# 15個の引数を持つキャラクター生成関数
# 引数の順序を覚えるのが困難、必須/オプションが混在

package Character;

sub new {
    my ($class, $name, $class_type, $level, $hp, $mp, $attack, $defense, $weapon, $armor, $accessory, $skill1, $skill2, $skill3, $title, $description) = @_;

    return bless {
        name        => $name       // 'Unknown',
        class_type  => $class_type // 'Fighter',
        level       => $level      // 1,
        hp          => $hp         // 100,
        mp          => $mp         // 0,
        attack      => $attack     // 10,
        defense     => $defense    // 5,
        weapon      => $weapon     // 'なし',
        armor       => $armor      // 'なし',
        accessory   => $accessory  // 'なし',
        skills      => [$skill1 // (), $skill2 // (), $skill3 // ()],
        title       => $title       // '',
        description => $description // '',
    }, $class;
}

sub show_status {
    my $self = shift;
    print "=== キャラクターステータス ===\n";
    print "名前: $self->{name}\n";
    print "称号: $self->{title}\n" if $self->{title};
    print "クラス: $self->{class_type} Lv.$self->{level}\n";
    print "HP: $self->{hp} / MP: $self->{mp}\n";
    print "攻撃力: $self->{attack} / 防御力: $self->{defense}\n";
    print "装備: 武器=$self->{weapon}, 防具=$self->{armor}, アクセ=$self->{accessory}\n";
    my @skills = grep {defined} @{$self->{skills}};
    print "スキル: ", join(', ', @skills), "\n" if @skills;
    print "説明: $self->{description}\n" if $self->{description};
    print "=" x 30, "\n";
}

package main;

# 使用例: 引数の順序を覚えるのが大変...
# 「アクセサリ」と「スキル1」の間に何があったっけ？

# 戦士キャラを作成
my $warrior = Character->new(
    '勇者',              # name
    '戦士',              # class_type
    10,                # level
    500,               # hp
    50,                # mp
    80,                # attack
    60,                # defense
    '伝説の剣',            # weapon
    'ミスリルの鎧',          # armor
    '力の指輪',            # accessory
    '斬撃',              # skill1
    '突進',              # skill2
    undef,             # skill3 (なし)
    '勇敢なる者',           # title
    '魔王討伐の任を受けた勇者',    # description
);

$warrior->show_status();

# 魔法使いを作成（引数の順序を間違えやすい...）
my $mage = Character->new(
    '賢者',              # name
    '魔法使い',            # class_type
    8,                 # level
    200,               # hp
    300,               # mp
    20,                # attack
    30,                # defense
    '魔法の杖',            # weapon
    'ローブ',             # armor
    '知恵の首飾り',          # accessory
    'ファイア',            # skill1
    'ブリザド',            # skill2
    'サンダー',            # skill3
    '大魔導師',            # title
    '古の魔法を操る賢者',       # description
);

$mage->show_status();

# 問題点:
# 1. 15個の引数の順序を覚えられない
# 2. オプション引数（スキル3など）を飛ばすのに undef が必要
# 3. どの引数が必須でどれがオプションか分からない
# 4. コードの可読性が低い
