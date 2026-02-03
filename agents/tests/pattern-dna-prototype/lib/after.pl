#!/usr/bin/env perl
use v5.36;
use warnings;

# コードドクター〜敵キャラクター量産緊急手術（Prototype）
# After: Prototypeパターンでクローン生成

package After::Enemy {
    use Moo;
    use Storable qw(dclone);

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

    # Prototypeパターン: クローンメソッド（深いコピー）
    sub clone ($self) {
        return After::Enemy->new(
            name       => $self->name,
            max_hp     => $self->max_hp,
            hp         => $self->max_hp,                # HPは最大値にリセット
            attack     => $self->attack,
            defense    => $self->defense,
            skills     => dclone($self->skills),        # 深いコピー
            drop_items => dclone($self->drop_items),    # 深いコピー
        );
    }
}

# Prototypeパターン: プロトタイプレジストリ
package After::EnemyRegistry {
    use Moo;

    has prototypes  => (is => 'ro', default => sub { {} });
    has _load_count => (is => 'rw', default => 0);

    # DBから敵のマスターデータを読み込む（1回だけ）
    sub _load_from_db ($self, $enemy_type) {
        say "  [DB] Loading '$enemy_type' master data from database...";
        $self->_load_count($self->_load_count + 1);

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

    # プロトタイプを登録（初回のみDBアクセス）
    sub register ($self, $enemy_type) {
        return if exists $self->prototypes->{$enemy_type};

        my $data = $self->_load_from_db($enemy_type);
        die "Unknown enemy type: $enemy_type" unless $data;

        # プロトタイプとして登録
        $self->prototypes->{$enemy_type} = After::Enemy->new(
            name       => $data->{name},
            max_hp     => $data->{max_hp},
            hp         => $data->{max_hp},
            attack     => $data->{attack},
            defense    => $data->{defense},
            skills     => $data->{skills},
            drop_items => $data->{drop_items},
        );
    }

    # プロトタイプからクローンを生成（DBアクセスなし！）
    sub create ($self, $enemy_type) {
        $self->register($enemy_type) unless exists $self->prototypes->{$enemy_type};

        return $self->prototypes->{$enemy_type}->clone;
    }

    # DB読み込み回数を取得
    sub load_count ($self) {
        return $self->_load_count;
    }
}

# メイン処理
sub main {
    say "=== After: Prototypeパターンでクローン生成 ===\n";

    my $registry = After::EnemyRegistry->new;

    # ゲーム開始時に使う敵の種類のプロトタイプを事前登録
    say "【初期化】プロトタイプを事前登録";
    $registry->register('slime');
    $registry->register('goblin');
    $registry->register('dragon');

    say "\n【シナリオ】ダンジョンに敵を配置する";
    say "";

    my @enemies;

    # スライムを5体生成（クローン）
    say "スライムを5体生成中...（クローン生成、DB読み込みなし）";
    for (1 .. 5) {
        push @enemies, $registry->create('slime');
    }

    # ゴブリンを3体生成（クローン）
    say "ゴブリンを3体生成中...（クローン生成、DB読み込みなし）";
    for (1 .. 3) {
        push @enemies, $registry->create('goblin');
    }

    # ドラゴンを2体生成（クローン）
    say "ドラゴンを2体生成中...（クローン生成、DB読み込みなし）";
    for (1 .. 2) {
        push @enemies, $registry->create('dragon');
    }

    say "\n--- 生成完了 ---";
    say "合計: " . scalar(@enemies) . "体の敵を生成";
    say "DB読み込み回数: " . $registry->load_count . "回（種類の数だけ！）";

    say "\n【生成された敵一覧】";
    for my $enemy (@enemies) {
        say "  - " . $enemy->info;
    }

    # 深いコピーのデモ
    say "\n【深いコピーの確認】";
    my $slime1 = $registry->create('slime');
    my $slime2 = $registry->create('slime');

    say "slime1のスキル: " . join(", ", @{$slime1->skills});
    say "slime2のスキル: " . join(", ", @{$slime2->skills});

    # slime1にだけスキルを追加
    push @{$slime1->skills}, "毒攻撃";

    say "\n★ slime1にだけ「毒攻撃」スキルを追加";
    say "slime1のスキル: " . join(", ", @{$slime1->skills});
    say "slime2のスキル: " . join(", ", @{$slime2->skills});
    say "→ 深いコピーなので、slime2には影響しない！";

    # 改善点の説明
    say "\n【改善点】";
    say "  ・敵の種類ごとに1回だけDBアクセス";
    say "  ・100体生成しても3回のDB読み込みで済む（種類が3つの場合）";
    say "  ・ゲーム開始時のロード時間が大幅に短縮";
    say "  ・深いコピーで個体ごとの変更が他に影響しない";
}

main() unless caller;

1;
