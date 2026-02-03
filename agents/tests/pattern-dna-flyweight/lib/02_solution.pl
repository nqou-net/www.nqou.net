#!/usr/bin/env perl
use v5.36;
use warnings;

# --- 処方: Flyweightパターン ---
# 共有可能な不変の状態（内部状態）を Flyweight オブジェクトとして独立させ、
# 工場（Factory）を通じて再利用することで、メモリ消費を劇的に抑える。

# Flyweight クラス: 内部状態（Intrinsic State）を保持
package TreeModel {
    use Moo;
    has name    => (is => 'ro', required => 1);
    has color   => (is => 'ro', required => 1);
    has mesh    => (is => 'ro', required => 1);
    has texture => (is => 'ro', required => 1);

    sub display {
        my ($self, $x, $y) = @_;
        # 内部状態と外部状態（$x, $y）を組み合わせて描画
        # say sprintf("Displaying %s at (%d, %d)", $self->name, $x, $y);
    }
}

# Flyweight Factory: Flyweight オブジェクトを管理・共有
package TreeFactory {
    use Moo;
    has _models => (is => 'ro', default => sub { {} });

    sub get_tree_type {
        my ($self, $name, $color, $mesh, $texture) = @_;
        
        # 既存のモデルがあれば再利用、なければ新規作成
        my $key = "$name-$color";
        if (!exists $self->_models->{$key}) {
            $self->_models->{$key} = TreeModel->new(
                name    => $name,
                color   => $color,
                mesh    => $mesh,
                texture => $texture,
            );
        }
        return $self->_models->{$key};
    }

    sub total_models {
        my $self = shift;
        return scalar keys %{$self->_models};
    }
}

# クライアントクラス: 外部状態（Extrinsic State）を保持
package Tree {
    use Moo;
    has x     => (is => 'ro', required => 1);
    has y     => (is => 'ro', required => 1);
    has type  => (is => 'ro', required => 1); # TreeModel への参照

    sub display {
        my $self = shift;
        $self->type->display($self->x, $self->y);
    }
}

package main;
use Devel::Size qw(size total_size);

say "--- 処置: Flyweightパターンによるメモリ最適化 ---";

my $factory = TreeFactory->new();
my @forest;
my $count = 1000;

# 重いデータの定義（実際は一度だけ作成される）
my $mesh    = "Heavy Mesh Data " . ("#" x 1000);
my $texture = "Heavy Texture Data " . ("*" x 1000);

for (my $i = 0; $i < $count; $i++) {
    my $type = $factory->get_tree_type("Cedar", "Green", $mesh, $texture);
    push @forest, Tree->new(x => rand(100), y => rand(100), type => $type);
}

say "木の一本あたりのサイズ (shallow): " . size($forest[0]) . " bytes";
say "木の一本あたりの合計サイズ (deep): " . total_size($forest[0]) . " bytes";
say "共有モデルの数: " . $factory->total_models();

# 全体のメモリ使用量（FactoryとForestの合計）
my $total_mem = total_size(\@forest) + total_size($factory);
say "$count 本の合計推定サイズ: $total_mem bytes";

foreach my $tree (@forest) {
    $tree->display();
}

say "森の生成が完了しました（メモリ消費が劇的に抑えられました）";
