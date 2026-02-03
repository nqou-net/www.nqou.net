#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

# テストファイル: Before/After 両方の動作確認

# -----------------------------------------------------------------------------
# Before コードのテスト
# -----------------------------------------------------------------------------
{

    package BeforeTest::Character;

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
}

subtest 'Before: 基本的なキャラクター生成' => sub {
    my $char = BeforeTest::Character->new('勇者', '戦士', 10, 500, 50, 80, 60, '伝説の剣', 'ミスリルの鎧', '力の指輪', '斬撃', '突進', undef, '勇敢なる者', '魔王討伐の任を受けた勇者');

    is($char->{name},       '勇者', '名前が正しい');
    is($char->{class_type}, '戦士', 'クラスが正しい');
    is($char->{level},      10,   'レベルが正しい');
    is($char->{hp},         500,  'HPが正しい');
    is($char->{attack},     80,   '攻撃力が正しい');
};

subtest 'Before: デフォルト値' => sub {
    my $char = BeforeTest::Character->new();

    is($char->{name},  'Unknown', 'デフォルト名');
    is($char->{level}, 1,         'デフォルトレベル');
    is($char->{hp},    100,       'デフォルトHP');
};

# -----------------------------------------------------------------------------
# After コードのテスト
# -----------------------------------------------------------------------------
{

    package AfterTest::Character;

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

    sub name       { shift->{name} }
    sub class_type { shift->{class_type} }
    sub level      { shift->{level} }
    sub hp         { shift->{hp} }
    sub mp         { shift->{mp} }
    sub attack     { shift->{attack} }
    sub defense    { shift->{defense} }
    sub skills     { @{shift->{skills}} }

    package AfterTest::CharacterBuilder;

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

    sub name        { my ($s, $v) = @_; $s->{name}       = $v; $s }
    sub class_type  { my ($s, $v) = @_; $s->{class_type} = $v; $s }
    sub level       { my ($s, $v) = @_; $s->{level}      = $v; $s }
    sub hp          { my ($s, $v) = @_; $s->{hp}         = $v; $s }
    sub mp          { my ($s, $v) = @_; $s->{mp}         = $v; $s }
    sub attack      { my ($s, $v) = @_; $s->{attack}     = $v; $s }
    sub defense     { my ($s, $v) = @_; $s->{defense}    = $v; $s }
    sub weapon      { my ($s, $v) = @_; $s->{weapon}     = $v; $s }
    sub armor       { my ($s, $v) = @_; $s->{armor}      = $v; $s }
    sub accessory   { my ($s, $v) = @_; $s->{accessory}  = $v; $s }
    sub add_skill   { my ($s, $v) = @_; push @{$s->{skills}}, $v; $s }
    sub title       { my ($s, $v) = @_; $s->{title} = $v; $s }
    sub description { my ($s, $v) = @_; $s->{description} = $v; $s }
    sub build       { AfterTest::Character->new(shift) }

    package AfterTest::CharacterDirector;

    sub new {
        my ($class, $builder) = @_;
        return bless {builder => $builder}, $class;
    }

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
}

subtest 'After: Builder でカスタムキャラ生成' => sub {
    my $char
        = AfterTest::CharacterBuilder->new()
        ->name('勇者')
        ->class_type('戦士')
        ->level(10)
        ->hp(500)
        ->mp(50)
        ->attack(80)
        ->defense(60)
        ->weapon('伝説の剣')
        ->armor('ミスリルの鎧')
        ->add_skill('斬撃')
        ->add_skill('突進')
        ->build();

    is($char->name,           '勇者', 'Builder: 名前');
    is($char->class_type,     '戦士', 'Builder: クラス');
    is($char->level,          10,   'Builder: レベル');
    is($char->hp,             500,  'Builder: HP');
    is($char->attack,         80,   'Builder: 攻撃力');
    is(scalar($char->skills), 2,    'Builder: スキル数');
};

subtest 'After: Builder デフォルト値' => sub {
    my $char = AfterTest::CharacterBuilder->new()->build();

    is($char->name,  'Unknown', 'デフォルト名');
    is($char->level, 1,         'デフォルトレベル');
    is($char->hp,    100,       'デフォルトHP');
};

subtest 'After: Director で戦士生成' => sub {
    my $director = AfterTest::CharacterDirector->new(AfterTest::CharacterBuilder->new());
    my $warrior  = $director->build_warrior('戦士A', 5);

    is($warrior->name,           '戦士A',        'Director: 名前');
    is($warrior->class_type,     '戦士',         'Director: クラス');
    is($warrior->level,          5,            'Director: レベル');
    is($warrior->hp,             100 + 5 * 30, 'Director: HP計算');     # 250
    is($warrior->attack,         15 + 5 * 5,   'Director: 攻撃力計算');    # 40
    is(scalar($warrior->skills), 2,            'Director: スキル数');
};

subtest 'After: Director で魔法使い生成' => sub {
    my $director = AfterTest::CharacterDirector->new(AfterTest::CharacterBuilder->new());
    my $mage     = $director->build_mage('魔導師B', 8);

    is($mage->name,           '魔導師B',       'Director: 名前');
    is($mage->class_type,     '魔法使い',       'Director: クラス');
    is($mage->level,          8,            'Director: レベル');
    is($mage->mp,             100 + 8 * 20, 'Director: MP計算');        # 260
    is(scalar($mage->skills), 3,            'Director: スキル数');
};

subtest 'After: メソッドチェーンの動作確認' => sub {
    my $builder = AfterTest::CharacterBuilder->new();

    # メソッドチェーンが正しく $self を返すか
    isa_ok($builder->name('Test'),     'AfterTest::CharacterBuilder');
    isa_ok($builder->level(5),         'AfterTest::CharacterBuilder');
    isa_ok($builder->add_skill('スキル'), 'AfterTest::CharacterBuilder');
};

done_testing();
