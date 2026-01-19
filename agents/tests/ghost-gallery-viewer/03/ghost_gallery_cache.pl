#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
# ファイル名: ghost_gallery_cache.pl

use v5.36;

# === 高解像度アート画像クラス（RealSubject） ===
package GhostImage {
    use Moo;
    use Time::HiRes qw(sleep);

    has name => ( is => 'ro', required => 1 );
    has resolution => ( is => 'ro', default => sub { '8K' } );

    sub BUILD ($self, $args) {
        say "  [LOADING] " . $self->name . "...";
        sleep(0.3);
        say "  [LOADED] " . $self->name;
    }

    sub render ($self) {
        return "🖼️ " . $self->name . " [" . $self->resolution . "]";
    }

    sub get_high_res_data ($self) {
        say "  [PROCESSING] 高解像度データを生成中...";
        sleep(0.5);
        return "HighResData<" . $self->name . ">";
    }
}

# === Virtual Proxy ===
package ImageProxy {
    use Moo;

    has name => ( is => 'ro', required => 1 );
    has resolution => ( is => 'ro', default => sub { '8K' } );
    has _real_image => ( is => 'lazy', init_arg => undef, builder => '_build_real_image' );

    sub _build_real_image ($self) {
        GhostImage->new(name => $self->name, resolution => $self->resolution);
    }

    sub render ($self) { "👻 " . $self->name . " [プレビュー]" }
    sub render_full ($self) { $self->_real_image->render }
    sub get_high_res_data ($self) { $self->_real_image->get_high_res_data }
}

# === Caching Proxy ===
package CacheProxy {
    use Moo;

    has inner_proxy => ( is => 'ro', required => 1 );
    has _cache => ( is => 'ro', default => sub { {} } );
    has cache_hits => ( is => 'rw', default => 0 );
    has cache_misses => ( is => 'rw', default => 0 );

    sub name ($self) { $self->inner_proxy->name }
    sub render ($self) { $self->inner_proxy->render }

    sub _cached ($self, $key, $code) {
        if (exists $self->_cache->{$key}) {
            say "  [CACHE HIT] $key";
            $self->cache_hits($self->cache_hits + 1);
            return $self->_cache->{$key};
        }
        say "  [CACHE MISS] $key";
        $self->cache_misses($self->cache_misses + 1);
        my $result = $code->();
        $self->_cache->{$key} = $result;
        return $result;
    }

    sub render_full ($self) {
        $self->_cached('render_full', sub { $self->inner_proxy->render_full });
    }

    sub get_high_res_data ($self) {
        $self->_cached('high_res', sub { $self->inner_proxy->get_high_res_data });
    }

    sub clear_cache ($self) { %{$self->_cache} = () }
    sub stats ($self) { "Hits: " . $self->cache_hits . ", Misses: " . $self->cache_misses }
}

# === ギャラリー ===
package GhostGallery {
    use Moo;

    has images => ( is => 'ro', default => sub { [] } );

    sub add_image ($self, $img) { push @{$self->images}, $img }

    sub show_gallery ($self) {
        say "\n=== 👻 ゴーストギャラリー ===\n";
        my $i = 1;
        say "$i. " . $_->render and $i++ for @{$self->images};
        say "\n============================\n";
    }

    sub view_image ($self, $idx) {
        my $img = $self->images->[$idx - 1];
        say "\n🔍 " . ($img ? $img->render_full : "not found");
    }
}

# === メイン ===
package main {
    my $gallery = GhostGallery->new;
    my $img = CacheProxy->new(inner_proxy => ImageProxy->new(name => '叫ぶ亡霊'));
    $gallery->add_image($img);

    $gallery->show_gallery;
    $gallery->view_image(1) for 1..3;

    say "\n📊 " . $img->stats;
}
