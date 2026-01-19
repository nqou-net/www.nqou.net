#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
# ファイル名: ghost_gallery_virtual.pl

use v5.36;

# === 高解像度アート画像クラス（RealSubject） ===
package GhostImage {
    use Moo;
    use Time::HiRes qw(sleep);

    has name => (
        is       => 'ro',
        required => 1,
    );

    has resolution => (
        is      => 'ro',
        default => sub { '8K' },
    );

    sub BUILD ($self, $args) {
        say "  [LOADING] " . $self->name . " (" . $self->resolution . ")...";
        sleep(0.5);
        say "  [LOADED] " . $self->name;
    }

    sub render ($self) {
        return "🖼️ " . $self->name . " [" . $self->resolution . "]";
    }

    sub get_full_data ($self) {
        return "FullImageData<" . $self->name . ">";
    }
}

# === Virtual Proxy ===
package ImageProxy {
    use Moo;

    has name => (
        is       => 'ro',
        required => 1,
    );

    has resolution => (
        is      => 'ro',
        default => sub { '8K' },
    );

    has _real_image => (
        is       => 'lazy',
        init_arg => undef,
        builder  => '_build_real_image',
    );

    sub _build_real_image ($self) {
        return GhostImage->new(
            name       => $self->name,
            resolution => $self->resolution,
        );
    }

    sub render ($self) {
        return "👻 " . $self->name . " [プレビュー]";
    }

    sub render_full ($self) {
        return $self->_real_image->render;
    }

    sub get_full_data ($self) {
        return $self->_real_image->get_full_data;
    }
}

# === ギャラリークラス ===
package GhostGallery {
    use Moo;

    has images => (
        is      => 'ro',
        default => sub { [] },
    );

    sub add_image ($self, $image) {
        push @{$self->images}, $image;
    }

    sub show_gallery ($self) {
        say "\n=== 👻 ゴーストギャラリー ===\n";
        my $index = 1;
        for my $image (@{$self->images}) {
            say "$index. " . $image->render;
            $index++;
        }
        say "\n============================\n";
    }

    sub view_image ($self, $index) {
        my $image = $self->images->[$index - 1];
        if ($image) {
            say "\n🔍 詳細表示中...";
            say $image->render_full;
        }
        else {
            say "画像が見つかりません。";
        }
    }
}

# === メイン処理 ===
package main {
    use v5.36;

    say "📸 ギャラリーを初期化中...\n";

    my $gallery = GhostGallery->new;

    $gallery->add_image(ImageProxy->new(name => '叫ぶ亡霊'));
    $gallery->add_image(ImageProxy->new(name => '真夜中の肖像画'));
    $gallery->add_image(ImageProxy->new(name => '消えた家族写真'));
    $gallery->add_image(ImageProxy->new(name => '赤い月の風景'));
    $gallery->add_image(ImageProxy->new(name => '最後の晩餐(呪)'));

    say "✅ 初期化完了!\n";

    $gallery->show_gallery;
    $gallery->view_image(2);
}
