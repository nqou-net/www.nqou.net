#!/usr/bin/env perl
use v5.36;

# Flyweight: 共有される香味オブジェクト
package FlavorDescriptor {
    use Moo;
    
    # 内部状態（intrinsic state）: 共有される
    has name     => (is => 'ro', required => 1);
    has category => (is => 'ro', required => 1);
    
    our $INSTANCE_COUNT = 0;
    
    sub BUILD($self, $args) {
        $INSTANCE_COUNT++;
    }
    
    sub describe($self, $intensity) {
        # 外部状態（extrinsic state）: 呼び出し時に渡される
        my $level = $intensity >= 7 ? 'strong' : $intensity >= 4 ? 'medium' : 'subtle';
        return sprintf("%s %s", $level, $self->name);
    }
}

# Flyweight Factory: オブジェクトプール
package FlavorPool {
    use Moo;
    
    has _pool => (
        is      => 'ro',
        default => sub { {} },
    );
    
    sub get_flavor($self, $name, $category) {
        my $key = "$category:$name";
        
        # プールに既にあれば再利用
        if (exists $self->_pool->{$key}) {
            return $self->_pool->{$key};
        }
        
        # 新規作成してプールに保存
        my $flavor = FlavorDescriptor->new(
            name     => $name,
            category => $category,
        );
        $self->_pool->{$key} = $flavor;
        
        return $flavor;
    }
    
    sub pool_size($self) {
        return scalar keys $self->_pool->%*;
    }
    
    sub list_flavors($self) {
        return [sort keys $self->_pool->%*];
    }
}

# カードクラス（Flyweightを利用）
package TastingCard {
    use Moo;
    
    has name         => (is => 'ro', required => 1);
    has flavor_pool  => (is => 'ro', required => 1);
    has flavor_refs  => (is => 'ro', default => sub { [] });
    
    sub add_flavor($self, $name, $category, $intensity = 5) {
        my $flavor = $self->flavor_pool->get_flavor($name, $category);
        push $self->flavor_refs->@*, { flavor => $flavor, intensity => $intensity };
    }
    
    sub render_flavors($self) {
        my @lines;
        for my $ref ($self->flavor_refs->@*) {
            push @lines, $ref->{flavor}->describe($ref->{intensity});
        }
        return join(", ", @lines);
    }
}

package main {
    my $pool = FlavorPool->new;
    
    # 100枚のカードを生成
    my @cards;
    for my $i (1..100) {
        my $card = TastingCard->new(
            name        => "Whisky #$i",
            flavor_pool => $pool,
        );
        
        # 全カードに同じ香味を追加（プールから取得）
        $card->add_flavor('smoky', 'nose', 8);
        $card->add_flavor('peaty', 'nose', 7);
        $card->add_flavor('vanilla', 'palate', 5);
        $card->add_flavor('honey', 'palate', 6);
        $card->add_flavor('long', 'finish', 9);
        
        push @cards, $card;
    }
    
    say "=== Flyweightパターンの効果 ===";
    say "カード数: " . scalar(@cards);
    say "FlavorDescriptorインスタンス数: $FlavorDescriptor::INSTANCE_COUNT";
    say "プールサイズ: " . $pool->pool_size . "種類";
    say "";
    say "プール内容: " . join(", ", $pool->list_flavors->@*);
    say "";
    say "--- サンプルカード ---";
    say "カード名: " . $cards[0]->name;
    say "香味: " . $cards[0]->render_flavors;
}
