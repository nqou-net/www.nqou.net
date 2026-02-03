#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

# =============================================================================
# After: Builder パターン適用
# =============================================================================
# メソッドチェーンで読みやすく、Director で定番パターンを再利用

# -----------------------------------------------------------------------------
# Character クラス（不変オブジェクト）
# -----------------------------------------------------------------------------
package Character;

sub new {
    my ($class, $builder) = @_;
    return bless {
        name        => $builder->{name},
        class_type  => $builder->{class_type},
        level       => $builder->{level},
        hp          => $builder->{hp},
        mp          => $builder->{mp},
        attack      => $builder->{attack},
        defense     => $builder->{defense},
        weapon      => $builder->{weapon},
        armor       => $builder->{armor},
        accessory   => $builder->{accessory},
        skills      => [@{$builder->{skills}}],
        title       => $builder->{title},
        description => $builder->{description},
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
    my @skills = grep { defined && $_ ne '' } @{$self->{skills}};
    print "スキル: ", join(', ', @skills), "\n" if @skills;
    print "説明: $self->{description}\n" if $self->{description};
    print "=" x 30, "\n";
}

# アクセサ
sub name       { shift->{name} }
sub class_type { shift->{class_type} }
sub level      { shift->{level} }
sub hp         { shift->{hp} }
sub mp         { shift->{mp} }
sub attack     { shift->{attack} }
sub defense    { shift->{defense} }

# -----------------------------------------------------------------------------
# CharacterBuilder クラス（流れるようなインターフェース）
# -----------------------------------------------------------------------------
package CharacterBuilder;

sub new {
    my $class = shift;
    return bless {
        name        => 'Unknown',
        class_type  => 'Fighter',
        level       => 1,
        hp          => 100,
        mp          => 0,
        attack      => 10,
        defense     => 5,
        weapon      => 'なし',
        armor       => 'なし',
        accessory   => 'なし',
        skills      => [],
        title       => '',
        description => '',
    }, $class;
}

# 基本情報
sub name {
    my ($self, $value) = @_;
    $self->{name} = $value;
    return $self;    # メソッドチェーン用
}

sub class_type {
    my ($self, $value) = @_;
    $self->{class_type} = $value;
    return $self;
}

sub level {
    my ($self, $value) = @_;
    $self->{level} = $value;
    return $self;
}

# ステータス
sub hp {
    my ($self, $value) = @_;
    $self->{hp} = $value;
    return $self;
}

sub mp {
    my ($self, $value) = @_;
    $self->{mp} = $value;
    return $self;
}

sub attack {
    my ($self, $value) = @_;
    $self->{attack} = $value;
    return $self;
}

sub defense {
    my ($self, $value) = @_;
    $self->{defense} = $value;
    return $self;
}

# 装備
sub weapon {
    my ($self, $value) = @_;
    $self->{weapon} = $value;
    return $self;
}

sub armor {
    my ($self, $value) = @_;
    $self->{armor} = $value;
    return $self;
}

sub accessory {
    my ($self, $value) = @_;
    $self->{accessory} = $value;
    return $self;
}

# スキル（可変長）
sub add_skill {
    my ($self, $skill) = @_;
    push @{$self->{skills}}, $skill;
    return $self;
}

# その他
sub title {
    my ($self, $value) = @_;
    $self->{title} = $value;
    return $self;
}

sub description {
    my ($self, $value) = @_;
    $self->{description} = $value;
    return $self;
}

# ビルド（Character を生成）
sub build {
    my $self = shift;
    return Character->new($self);
}

# -----------------------------------------------------------------------------
# CharacterDirector クラス（定番キャラ生成）
# -----------------------------------------------------------------------------
package CharacterDirector;

sub new {
    my ($class, $builder) = @_;
    return bless {builder => $builder}, $class;
}

# 戦士テンプレート
sub build_warrior {
    my ($self, $name, $level) = @_;
    $level //= 1;

    return $self->{builder}->name($name)
        ->class_type('戦士')
        ->level($level)
        ->hp(100 + $level * 30)
        ->mp(10 + $level * 2)
        ->attack(15 + $level * 5)
        ->defense(10 + $level * 4)
        ->weapon('ロングソード')
        ->armor('チェインメイル')
        ->add_skill('斬撃')
        ->add_skill('防御態勢')
        ->build();
}

# 魔法使いテンプレート
sub build_mage {
    my ($self, $name, $level) = @_;
    $level //= 1;

    return $self->{builder}->name($name)
        ->class_type('魔法使い')
        ->level($level)
        ->hp(50 + $level * 15)
        ->mp(100 + $level * 20)
        ->attack(5 + $level * 2)
        ->defense(5 + $level * 2)
        ->weapon('魔法の杖')
        ->armor('ローブ')
        ->add_skill('ファイア')
        ->add_skill('ブリザド')
        ->add_skill('サンダー')
        ->build();
}

# 盗賊テンプレート
sub build_thief {
    my ($self, $name, $level) = @_;
    $level //= 1;

    return $self->{builder}->name($name)
        ->class_type('盗賊')
        ->level($level)
        ->hp(70 + $level * 20)
        ->mp(30 + $level * 5)
        ->attack(12 + $level * 4)
        ->defense(6 + $level * 2)
        ->weapon('ダガー')
        ->armor('レザーアーマー')
        ->accessory('素早さの靴')
        ->add_skill('不意打ち')
        ->add_skill('鍵開け')
        ->build();
}

# -----------------------------------------------------------------------------
# 使用例
# -----------------------------------------------------------------------------
package main;

print "【Builder パターン適用後】\n\n";

# 方法1: Builder で詳細にカスタマイズ
print "--- カスタムキャラ（Builder 直接使用）---\n";
my $hero
    = CharacterBuilder->new()
    ->name('勇者')
    ->class_type('戦士')
    ->level(10)
    ->hp(500)
    ->mp(50)
    ->attack(80)
    ->defense(60)
    ->weapon('伝説の剣')
    ->armor('ミスリルの鎧')
    ->accessory('力の指輪')
    ->add_skill('斬撃')
    ->add_skill('突進')
    ->title('勇敢なる者')
    ->description('魔王討伐の任を受けた勇者')
    ->build();

$hero->show_status();

# 方法2: Director で定番キャラを素早く生成
print "--- 定番キャラ（Director 使用）---\n";
my $director = CharacterDirector->new(CharacterBuilder->new());

my $warrior = $director->build_warrior('戦士A', 5);
$warrior->show_status();

$director = CharacterDirector->new(CharacterBuilder->new());
my $mage = $director->build_mage('魔導師B', 8);
$mage->show_status();

$director = CharacterDirector->new(CharacterBuilder->new());
my $thief = $director->build_thief('盗賊C', 3);
$thief->show_status();

# 改善点:
# 1. 引数の順序を覚える必要がない（メソッド名で明示）
# 2. オプション項目は呼ばなければ良い
# 3. メソッドチェーンで可読性が高い
# 4. Director で定番パターンを再利用可能
