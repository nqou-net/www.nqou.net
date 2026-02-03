#!/usr/bin/env perl
use v5.36;
use warnings;

# --- 症状: インスタンス増殖症 ---
# 木のオブジェクトを数万個作ろうとすると、
# 各オブジェクトが重いデータ（メッシュやテクスチャ）を個別に保持しているため
# メモリを大量に消費してしまう。

package Tree {
    use Moo;

    # 外部状態（座標）
    has x => (is => 'ro', required => 1);
    has y => (is => 'ro', required => 1);

    # 本来は「内部状態（共有可能）」であるべきデータ
    # 各インスタンスが個別に持ってしまっている（冗長状態肥大化）
    has name    => (is => 'ro', default => 'Cedar');
    has color   => (is => 'ro', default => 'Green');
    has mesh    => (is => 'ro', default => sub { "Heavy Mesh Data " . ("#" x 1000) });
    has texture => (is => 'ro', default => sub { "Heavy Texture Data " . ("*" x 1000) });

    sub display {
        my $self = shift;
        # 描画のシミュレーション
        # say sprintf("Displaying %s at (%d, %d)", $self->name, $self->x, $self->y);
    }
}

package main;
use Devel::Size qw(size total_size);

say "--- 診断: インスタンス増殖症のシミュレーション ---";

my @forest;
my $count = 1000; # デモ用に1000個

for (my $i = 0; $i < $count; $i++) {
    push @forest, Tree->new(x => rand(100), y => rand(100));
}

say "木の一本あたりのサイズ (shallow): " . size($forest[0]) . " bytes";
say "木の一本あたりの合計サイズ (deep): " . total_size($forest[0]) . " bytes";
say "$count 本の合計推定サイズ: " . total_size(\@forest) . " bytes";

foreach my $tree (@forest) {
    $tree->display();
}

say "森の生成が完了しました（メモリを大量に消費しました）";
