#!/usr/bin/env perl
use v5.36;

# ====================
# Strategy パターン: 記述戦略
# ====================
package DescriptionStrategy {
    use Moo::Role;
    requires 'format_description';
}

package PoeticStrategy {
    use Moo;
    with 'DescriptionStrategy';
    
    sub format_description($self, $profile) {
        my $flavors = $profile->get_flavors();
        return sprintf(
            "%s %d年: %s\n香味: %s",
            $profile->name,
            $profile->age,
            $flavors->{poetic_description},
            join(', ', $flavors->{notes}->@*)
        );
    }
}

package TechnicalStrategy {
    use Moo;
    with 'DescriptionStrategy';
    
    sub format_description($self, $profile) {
        my $flavors = $profile->get_flavors();
        return sprintf(
            "%s %d年 [%s]\n度数: %d%% | 樽: %s\n成分特性: %s",
            $profile->name,
            $profile->age,
            $profile->type,
            $flavors->{abv} // 43,
            $flavors->{cask_type} // '不明',
            join(', ', $flavors->{technical_notes}->@*)
        );
    }
}

package BeginnerStrategy {
    use Moo;
    with 'DescriptionStrategy';
    
    sub format_description($self, $profile) {
        my $flavors = $profile->get_flavors();
        return sprintf(
            "%s (%d年もの)\n🥃 %s\n👍 おすすめ度: %s",
            $profile->name,
            $profile->age,
            $flavors->{simple_description},
            '★' x ($flavors->{beginner_friendly} // 3)
        );
    }
}

# ====================
# WhiskyProfile Role
# ====================
package WhiskyProfile {
    use Moo::Role;
    
    has name => (is => 'ro', required => 1);
    has age  => (
        is       => 'ro',
        isa      => sub { die "Age must be positive" unless $_[0] > 0 },
        required => 1,
    );
    has type => (is => 'ro', required => 1);
    has strategy => (
        is      => 'ro',
        does    => 'DescriptionStrategy',
        default => sub { PoeticStrategy->new },
    );
    
    requires 'get_flavors';
    
    sub describe($self) {
        return $self->strategy->format_description($self);
    }
}

# ====================
# 具象プロファイル群
# ====================
package ScotchProfile {
    use Moo;
    with 'WhiskyProfile';
    
    sub get_flavors($self) {
        return {
            poetic_description  => 'スコットランドの荒々しい大地を思わせる、'
                                 . 'ピートの煙と海の香り。琥珀色の液体に秘められた複雑な物語。',
            simple_description  => 'スモーキーで力強い味わい。海辺のウイスキー！',
            notes               => ['ピート', '海藻', 'ヨード', 'オーク'],
            technical_notes     => ['フェノール値35ppm', '塩味強', 'ヨード香顕著'],
            cask_type           => 'バーボン樽',
            abv                 => 43,
            beginner_friendly   => 2,
        };
    }
}

package BourbonProfile {
    use Moo;
    with 'WhiskyProfile';
    
    sub get_flavors($self) {
        return {
            poetic_description  => '焦がしたオークとバニラの甘美なハーモニー、'
                                 . 'ケンタッキーの夕暮れのような温かみ。',
            simple_description  => '甘くて飲みやすい、バニラとカラメルの香り！',
            notes               => ['バニラ', 'カラメル', 'オーク', 'トウモロコシの甘み'],
            technical_notes     => ['トウモロコシ含有率70%', 'チャーレベル4', 'エステル高'],
            cask_type           => '新品チャー樽',
            abv                 => 45,
            beginner_friendly   => 5,
        };
    }
}

package IrishProfile {
    use Moo;
    with 'WhiskyProfile';
    
    sub get_flavors($self) {
        return {
            poetic_description  => '三回蒸留による滑らかさ、'
                                 . 'エメラルドの島の穏やかな風のよう。',
            simple_description  => 'なめらかで優しい味わい。初心者に最適！',
            notes               => ['ハチミツ', 'バニラ', 'グリーンアップル', 'クリーム'],
            technical_notes     => ['三回蒸留', 'ノンピート', '軽快な口当たり'],
            cask_type           => 'シェリー樽',
            abv                 => 40,
            beginner_friendly   => 5,
        };
    }
}

package JapaneseProfile {
    use Moo;
    with 'WhiskyProfile';
    
    sub get_flavors($self) {
        return {
            poetic_description  => '繊細な日本の四季を映し出す、バランスの芸術。'
                                 . '水明りのような透明感と深み。',
            simple_description  => 'バランスが良く飲みやすい。フルーティで上品！',
            notes               => ['桜', '梅', 'ミズナラ', '緑茶', 'はちみつ'],
            technical_notes     => ['ミズナラ樽熟成', '軟水仕込み', '独自ブレンド技術'],
            cask_type           => 'ミズナラ樽',
            abv                 => 43,
            beginner_friendly   => 4,
        };
    }
}

# ====================
# Factory Method: WhiskyFactory
# ====================
package WhiskyFactory {
    use Moo;
    
    sub create_profile($self, $type, %args) {
        my %profile_map = (
            scotch   => 'ScotchProfile',
            bourbon  => 'BourbonProfile',
            irish    => 'IrishProfile',
            japanese => 'JapaneseProfile',
        );
        
        my $class = $profile_map{lc $type}
            or die "Unknown whisky type: $type";
        
        return $class->new(type => $type, %args);
    }
    
    sub create_with_strategy($self, $type, $strategy_type, %args) {
        my %strategy_map = (
            poetic    => 'PoeticStrategy',
            technical => 'TechnicalStrategy',
            beginner  => 'BeginnerStrategy',
        );
        
        my $strategy_class = $strategy_map{lc $strategy_type}
            or die "Unknown strategy type: $strategy_type";
        
        my $strategy = $strategy_class->new;
        
        return $self->create_profile($type, strategy => $strategy, %args);
    }
}

# ====================
# メイン処理
# ====================
package main {
    say "=" x 70;
    say "🥃 ウイスキー香味プロファイル生成器";
    say "   Factory Method + Strategy パターン統合デモ";
    say "=" x 70;
    say "";
    
    my $factory = WhiskyFactory->new;
    
    # デモ1: 各種ウイスキーをデフォルト戦略（詩的）で表示
    say "【デモ1】Factory Method: 各種ウイスキーを生成";
    say "-" x 70;
    
    my @whiskies = (
        $factory->create_profile('scotch', name => 'Laphroaig', age => 10),
        $factory->create_profile('bourbon', name => "Maker's Mark", age => 6),
        $factory->create_profile('irish', name => 'Jameson', age => 12),
        $factory->create_profile('japanese', name => '山崎', age => 18),
    );
    
    for my $whisky (@whiskies) {
        say $whisky->describe();
        say "";
    }
    
    # デモ2: 同じウイスキーを3つの視点で
    say "=" x 70;
    say "【デモ2】Strategy パターン: 同じウイスキーを3つの視点で記述";
    say "-" x 70;
    say "";
    
    for my $style (qw/poetic technical beginner/) {
        my $whisky = $factory->create_with_strategy(
            'scotch',
            $style,
            name => 'Ardbeg',
            age  => 10,
        );
        
        say "■ " . uc($style) . " VIEW:";
        say $whisky->describe();
        say "";
    }
    
    # デモ3: 型制約のテスト
    say "=" x 70;
    say "【デモ3】Mooの型制約テスト";
    say "-" x 70;
    
    eval {
        my $invalid = $factory->create_profile('scotch', name => 'Test', age => -5);
    };
    say "✓ 負の年数でエラー検出: $@" if $@;
    
    eval {
        my $invalid_type = $factory->create_profile('vodka', name => 'Test', age => 5);
    };
    say "✓ 未知のタイプでエラー検出: $@" if $@;
    
    say "\n" . "=" x 70;
    say "🎉 デモンストレーション完了！";
    say "=" x 70;
}
