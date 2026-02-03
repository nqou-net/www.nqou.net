#!/usr/bin/env perl
use v5.36;
use warnings;

# コードドクター〜敵キャラクター量産緊急手術（Prototype）
# Before: 毎回DBから設定を読み込んで敵を生成

package Before::Enemy {
    use Moo;

    has name       => (is => 'ro', required => 1);
    has max_hp     => (is => 'ro', required => 1);
    has hp         => (is => 'rw', required => 1);
    has attack     => (is => 'ro', required => 1);
    has defense    => (is => 'ro', required => 1);
    has skills     => (is => 'ro', default  => sub { [] });
    has drop_items => (is => 'ro', default  => sub { [] });

    sub take_damage ($self, $damage) {
        my $actual = $damage - $self->defense;
        $actual = 1 if $actual < 1;
        $self->hp($self->hp - $actual);
        return $actual;
    }

    sub is_alive ($self) {
        return $self->hp > 0;
    }

    sub info ($self) {
        return sprintf("%s [HP: %d/%d, ATK: %d, DEF: %d]", $self->name, $self->hp, $self->max_hp, $self->attack, $self->defense);
    }
}

# 問題のあるコード: EnemyFactory（毎回DBから読み込み）
package Before::EnemyFactory {
    use Moo;

    # DBから敵のマスターデータを読み込む（シミュレーション）
    # 実際は DBI->connect して SELECT するイメージ
    sub _load_from_db ($self, $enemy_type) {

        # 重い処理をシミュレート（実際はDB接続・クエリ実行）
        say "  [DB] Loading '$enemy_type' master data from database...";

        # マスターデータ（実際はDBから取得）
        my %master_data = (
            slime => {
                name       => 'スライム',
                max_hp     => 30,
                attack     => 5,
                defense    => 2,
                skills     => ['体当たり'],
                drop_items => ['スライムゼリー', '回復薬'],
            },
            goblin => {
                name       => 'ゴブリン',
                max_hp     => 50,
                attack     => 12,
                defense    => 5,
                skills     => ['突進',     'かみつき'],
                drop_items => ['ゴブリンの牙', '小さな宝石'],
            },
            dragon => {
                name       => 'ドラゴン',
                max_hp     => 500,
                attack     => 80,
                defense    => 40,
                skills     => ['火炎ブレス',  '尻尾攻撃',   '咆哮'],
                drop_items => ['ドラゴンの鱗', 'ドラゴンの牙', '竜の宝玉'],
            },
        );

        return $master_data{$enemy_type};
    }

    # 敵を生成（毎回DBから読み込む = 遅い！）
    sub create ($self, $enemy_type) {
        my $data = $self->_load_from_db($enemy_type);

        die "Unknown enemy type: $enemy_type" unless $data;

        return Before::Enemy->new(
            name       => $data->{name},
            max_hp     => $data->{max_hp},
            hp         => $data->{max_hp},             # 初期HPは最大値
            attack     => $data->{attack},
            defense    => $data->{defense},
            skills     => [@{$data->{skills}}],        # 配列のコピー
            drop_items => [@{$data->{drop_items}}],    # 配列のコピー
        );
    }
}

# メイン処理
sub main {
    say "=== Before: 毎回DBから読み込んで敵を生成 ===\n";

    my $factory = Before::EnemyFactory->new;

    # ゲーム開始時に敵を100体生成（例として10体で示す）
    say "【シナリオ】ダンジョンに敵を配置する";
    say "";

    my @enemies;
    my $start = time;

    # スライムを5体生成
    say "スライムを5体生成中...";
    for (1 .. 5) {
        push @enemies, $factory->create('slime');
    }

    # ゴブリンを3体生成
    say "\nゴブリンを3体生成中...";
    for (1 .. 3) {
        push @enemies, $factory->create('goblin');
    }

    # ドラゴンを2体生成
    say "\nドラゴンを2体生成中...";
    for (1 .. 2) {
        push @enemies, $factory->create('dragon');
    }

    say "\n--- 生成完了 ---";
    say "合計: " . scalar(@enemies) . "体の敵を生成";
    say "DB読み込み回数: " . scalar(@enemies) . "回（敵の数だけ読み込み！）";

    say "\n【生成された敵一覧】";
    for my $enemy (@enemies) {
        say "  - " . $enemy->info;
    }

    # 問題点の説明
    say "\n【問題点】";
    say "  ・敵を1体生成するたびにDBにアクセスしている";
    say "  ・100体生成すると100回のDB読み込みが発生";
    say "  ・ゲーム開始時のロード時間が長くなる";
    say "  ・プレイヤーから「ロード遅い！」とクレームが来る";
}

main() unless caller;

1;
