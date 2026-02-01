#!/usr/bin/env perl
use v5.36;

# Cloneable Role: クローン機能を提供
package Cloneable {
    use Moo::Role;
    use Storable qw(dclone);
    
    sub clone($self) {
        # 深いコピーを作成
        return dclone($self);
    }
    
    sub clone_with($self, %overrides) {
        my $cloned = $self->clone;
        
        # 指定された属性だけ上書き
        for my $key (keys %overrides) {
            if ($cloned->can($key)) {
                $cloned->$key($overrides{$key});
            }
        }
        
        return $cloned;
    }
}

package WhiskyProfile {
    use Moo;
    with 'Cloneable';
    
    has region       => (is => 'ro', required => 1);
    has sub_region   => (is => 'ro', default => '');
    has distillery   => (is => 'rw', default => 'Generic');
    has nose_notes   => (is => 'rw', default => sub { [] });
    has palate_notes => (is => 'rw', default => sub { [] });
    has finish_notes => (is => 'rw', default => sub { [] });
    has peat_level   => (is => 'rw', default => 5);
    has smoke_level  => (is => 'rw', default => 5);
    has sweetness    => (is => 'rw', default => 5);
    
    sub describe($self) {
        return sprintf(
            "Distillery: %s\nRegion: %s (%s)\nPeat: %d, Smoke: %d, Sweet: %d\nNose: %s",
            $self->distillery,
            $self->region,
            $self->sub_region || 'general',
            $self->peat_level,
            $self->smoke_level,
            $self->sweetness,
            join(', ', $self->nose_notes->@*),
        );
    }
}

package main {
    say "=== Prototypeパターンによる派生作成 ===\n";
    
    # Islayの基本プロファイル（プロトタイプ）
    my $islay_base = WhiskyProfile->new(
        region       => 'Scotland',
        sub_region   => 'Islay',
        distillery   => 'Islay Base',
        nose_notes   => ['smoky', 'peaty', 'maritime'],
        palate_notes => ['intense smoke', 'brine', 'pepper'],
        finish_notes => ['long', 'warming'],
        peat_level   => 8,
        smoke_level  => 8,
        sweetness    => 3,
    );
    
    say "--- Islay Base Profile ---";
    say $islay_base->describe;
    say "";
    
    # Ardbeg風: クローンして一部だけ変更
    my $ardbeg = $islay_base->clone_with(
        distillery  => 'Ardbeg',
        peat_level  => 10,
        smoke_level => 10,
        sweetness   => 2,
    );
    
    say "--- Ardbeg Style (cloned from base) ---";
    say $ardbeg->describe;
    say "";
    
    # Laphroaig風: クローンして別の変更
    my $laphroaig = $islay_base->clone_with(
        distillery => 'Laphroaig',
        peat_level => 9,
    );
    $laphroaig->nose_notes(['smoky', 'peaty', 'maritime', 'medicinal', 'seaweed']);
    
    say "--- Laphroaig Style (cloned from base) ---";
    say $laphroaig->describe;
    say "";
    
    # Bowmore風: Ardbegからさらに派生
    my $bowmore = $ardbeg->clone_with(
        distillery  => 'Bowmore',
        peat_level  => 6,
        smoke_level => 5,
        sweetness   => 5,
    );
    
    say "--- Bowmore Style (cloned from Ardbeg) ---";
    say $bowmore->describe;
}
