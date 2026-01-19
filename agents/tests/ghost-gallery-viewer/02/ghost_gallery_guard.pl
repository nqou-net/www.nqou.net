#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
# ファイル名: ghost_gallery_guard.pl

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
        say "  [LOADING] " . $self->name . "...";
        sleep(0.3);
        say "  [LOADED] " . $self->name;
    }

    sub render ($self) {
        return "🖼️ " . $self->name . " [" . $self->resolution . "]";
    }
}

# === Virtual Proxy ===
package ImageProxy {
    use Moo;

    has name => ( is => 'ro', required => 1 );
    has resolution => ( is => 'ro', default => sub { '8K' } );

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

    sub render ($self) { "👻 " . $self->name . " [プレビュー]" }
    sub render_full ($self) { $self->_real_image->render }
}

# === Protection Proxy (Guard Proxy) ===
package GuardProxy {
    use Moo;

    has inner_proxy => ( is => 'ro', required => 1 );
    has required_roles => ( is => 'ro', default => sub { ['admin', 'vip'] } );
    has current_user => ( is => 'rw', default => sub { { role => 'guest' } } );

    sub name ($self) { $self->inner_proxy->name }

    sub _check_access ($self) {
        my $role = $self->current_user->{role} // 'guest';
        return grep { $_ eq $role } @{$self->required_roles};
    }

    sub render ($self) {
        $self->_check_access
            ? "🔓 " . $self->inner_proxy->render
            : "🔒 [鍵付き] " . $self->inner_proxy->name;
    }

    sub render_full ($self) {
        return "⛔ [アクセス拒否] " . $self->inner_proxy->name
            unless $self->_check_access;
        return $self->inner_proxy->render_full;
    }
}

# === ギャラリークラス ===
package GhostGallery {
    use Moo;

    has images => ( is => 'ro', default => sub { [] } );
    has current_user => ( is => 'rw', default => sub { { role => 'guest' } } );

    sub add_image ($self, $img) { push @{$self->images}, $img }

    sub set_user ($self, $user) {
        $self->current_user($user);
        $_->current_user($user) for grep { $_->isa('GuardProxy') } @{$self->images};
    }

    sub show_gallery ($self) {
        say "\n=== 👻 ゴーストギャラリー ===";
        say "ログイン: " . ($self->current_user->{name} // 'ゲスト') . "\n";
        my $i = 1;
        say "$i. " . $_->render and $i++ for @{$self->images};
        say "\n============================\n";
    }

    sub view_image ($self, $idx) {
        my $img = $self->images->[$idx - 1];
        say "\n🔍 詳細表示...\n" . ($img ? $img->render_full : "画像が見つかりません");
    }
}

# === メイン ===
package main {
    my $gallery = GhostGallery->new;

    $gallery->add_image(ImageProxy->new(name => '叫ぶ亡霊'));
    $gallery->add_image(GuardProxy->new(inner_proxy => ImageProxy->new(name => '禁断の肖像画')));
    $gallery->add_image(ImageProxy->new(name => '消えた家族写真'));
    $gallery->add_image(GuardProxy->new(inner_proxy => ImageProxy->new(name => '呪われた王冠'), required_roles => ['vip']));

    $gallery->show_gallery;
    $gallery->view_image(2);

    say "\n" . "=" x 40 . "\n";

    $gallery->set_user({ name => 'VIP太郎', role => 'vip' });
    $gallery->show_gallery;
    $gallery->view_image(2);
}
