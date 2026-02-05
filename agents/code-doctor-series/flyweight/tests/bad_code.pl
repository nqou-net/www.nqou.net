use v5.36;

# 悪い実装: 全てのインスタンスが巨大なデータを個別に持っている

package Goblin {
    use Time::HiRes qw(sleep);

    sub new ($class, %args) {

        # 毎回重いデータをロードしている（シミュレーション）
        my $heavy_mesh    = "X" x (1024 * 10);    # 10KB Mesh
        my $heavy_texture = "Y" x (1024 * 50);    # 50KB Texture

        return bless {
            name      => 'Goblin',
            mesh      => $heavy_mesh,
            texture   => $heavy_texture,
            animation => ['idle', 'walk', 'attack', 'die'],    # 共通データ
            x         => $args{x} || 0,
            y         => $args{y} || 0,
            hp        => 50,
        }, $class;
    }

    sub draw ($self) {

        # 描画処理（本来はmeshとtextureを使う）
        # say "Drawing $self->{name} at ($self->{x}, $self->{y})";
    }
}

# インスタンス生成テスト
my @goblins;
my $start_mem = `ps -o rss= -p $$`;

say "Creating 10,000 Goblins...";
for (1 .. 10000) {
    push @goblins, Goblin->new(x => $_, y => $_);
}

my $end_mem = `ps -o rss= -p $$`;
say "Memory Usage Increase: " . ($end_mem - $start_mem) . " KB";
