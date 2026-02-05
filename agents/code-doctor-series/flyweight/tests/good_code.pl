use v5.36;

# 良い実装: 変化しないデータ（Intrinsic State）を共有する

# 1. Flyweight (共有されるオブジェクト)
package GoblinType {

    sub new ($class) {

        # 重いデータはここで一度だけ作られる
        my $heavy_mesh    = "X" x (1024 * 10);
        my $heavy_texture = "Y" x (1024 * 50);

        return bless {
            name      => 'Goblin',
            mesh      => $heavy_mesh,
            texture   => $heavy_texture,
            animation => ['idle', 'walk', 'attack', 'die'],
        }, $class;
    }

    sub draw ($self, $context) {

        # 描画処理にはContext（外部状態）を使う
        # say "Drawing $self->{name} at ($context->{x}, $context->{y})";
    }
}

# 2. Factory (Flyweightを管理・提供する工場)
package UnitFactory {
    my %pool;

    sub get_unit_type ($class, $type_name) {

        # まだ無ければ作る、あれば返す（Cache）
        return $pool{$type_name} //= "${type_name}Type"->new();
    }
}

# 3. Context (個別のインスタンス)
package Goblin {

    sub new ($class, %args) {
        return bless {

            # 参照（ポインタ）のみを持つ
            type => UnitFactory->get_unit_type('Goblin'),

            # 外的状態（Extrinsic State）のみインスタンスが持つ
            x  => $args{x} || 0,
            y  => $args{y} || 0,
            hp => 50,
        }, $class;
    }

    sub draw ($self) {

        # 実処理はTypeに委譲し、自分の状態（Context）を渡す
        $self->{type}->draw($self);
    }
}

# インスタンス生成テスト
my @goblins;
my $start_mem = `ps -o rss= -p $$`;

say "Creating 10,000 Goblins (Flyweight)...";
for (1 .. 10000) {
    push @goblins, Goblin->new(x => $_, y => $_);
}

my $end_mem = `ps -o rss= -p $$`;
say "Memory Usage Increase: " . ($end_mem - $start_mem) . " KB";
