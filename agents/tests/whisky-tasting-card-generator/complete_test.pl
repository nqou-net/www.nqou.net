#!/usr/bin/env perl
use v5.36;

# === Flyweight: 香味プール ===
package FlavorPool {
    use Moo;
    
    my $_instance;
    has _pool => (is => 'ro', default => sub { {} });
    
    sub instance { $_instance //= __PACKAGE__->new }
    
    sub get($self, $name, $category) {
        my $key = "$category:$name";
        $self->_pool->{$key} //= FlavorDescriptor->new(
            name => $name, category => $category
        );
        return $self->_pool->{$key};
    }
}

package FlavorDescriptor {
    use Moo;
    has name     => (is => 'ro', required => 1);
    has category => (is => 'ro', required => 1);
}

# === Prototype: クローン可能プロファイル ===
package Cloneable {
    use Moo::Role;
    use Storable qw(dclone);
    
    sub clone($self) { dclone($self) }
    
    sub clone_with($self, %overrides) {
        my $c = $self->clone;
        $c->$_($overrides{$_}) for grep { $c->can($_) } keys %overrides;
        return $c;
    }
}

package WhiskyProfile {
    use Moo;
    with 'Cloneable';
    
    has distillery => (is => 'rw', required => 1);
    has peat_level => (is => 'rw', default => 5);
    has flavors    => (is => 'rw', default => sub { [] });
    
    sub add_flavor($self, $name, $category) {
        push $self->flavors->@*, FlavorPool->instance->get($name, $category);
    }
}

# === Abstract Factory: 産地別キット生成 ===
package TastingKitFactory::Role {
    use Moo::Role;
    requires 'create_base_profile';
    requires 'create_card';
}

package ScotchFactory {
    use Moo;
    with 'TastingKitFactory::Role';
    
    sub create_base_profile($self) {
        my $profile = WhiskyProfile->new(distillery => 'Islay Base', peat_level => 8);
        $profile->add_flavor('smoky', 'nose');
        $profile->add_flavor('peaty', 'nose');
        return $profile;
    }
    
    sub create_card($self, $profile) {
        return TastingCard->new(profile => $profile);
    }
}

package TastingCard {
    use Moo;
    has profile => (is => 'ro', required => 1);
    
    sub render($self) {
        my $p = $self->profile;
        my $flavors = join(', ', map { $_->name } $p->flavors->@*);
        return sprintf(
            "┏━━━ TASTING CARD ━━━┓\n┃ %s (Peat: %d)\n┃ Flavors: %s\n┗━━━━━━━━━━━━━━━━━━━━┛",
            $p->distillery, $p->peat_level, $flavors
        );
    }
}

# === メイン処理: 3パターンの統合 ===
package main {
    say "=== ウイスキーテイスティングカード生成器 v1.0 ===";
    say "=== Abstract Factory × Flyweight × Prototype ===\n";
    
    # Abstract Factory: 産地別ファクトリでベースプロファイル作成
    my $scotch_factory = ScotchFactory->new;
    my $base = $scotch_factory->create_base_profile;
    
    say "--- Base Profile ---";
    say $scotch_factory->create_card($base)->render;
    say "";
    
    # Prototype: ベースをクローンして派生を作成
    my $ardbeg = $base->clone_with(distillery => 'Ardbeg', peat_level => 10);
    my $bowmore = $base->clone_with(distillery => 'Bowmore', peat_level => 5);
    
    say "--- Ardbeg (cloned) ---";
    say $scotch_factory->create_card($ardbeg)->render;
    say "";
    
    say "--- Bowmore (cloned) ---";
    say $scotch_factory->create_card($bowmore)->render;
    say "";
    
    # Flyweight: 香味オブジェクトの共有状況
    my $pool = FlavorPool->instance;
    say "=== Flyweight Pool Status ===";
    say "共有香味オブジェクト数: " . scalar(keys $pool->_pool->%*);
    say "プール内容: " . join(', ', sort keys $pool->_pool->%*);
}
