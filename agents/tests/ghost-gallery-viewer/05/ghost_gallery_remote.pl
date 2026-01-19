#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
# ファイル名: ghost_gallery_remote.pl

use v5.36;

# === ローカル画像 ===
package GhostImage {
    use Moo;
    use Time::HiRes qw(sleep);

    has name => ( is => 'ro', required => 1 );
    has resolution => ( is => 'ro', default => sub { '8K' } );

    sub BUILD ($self, $args) { sleep(0.2) }
    sub render ($self) { "🖼️ " . $self->name . " [" . $self->resolution . "] (local)" }
    sub render_full ($self) { $self->render }
}

# === HTTPクライアント（モック） ===
package ArchiveClient {
    use Moo;
    use Time::HiRes qw(sleep);

    has base_url => ( is => 'ro', default => sub { 'https://archive.example.com' } );
    has is_online => ( is => 'rw', default => 1 );

    sub fetch_image ($self, $image_id) {
        return { success => 0, reason => 'Network offline' } unless $self->is_online;
        say "  [HTTP] GET " . $self->base_url . "/images/$image_id";
        sleep(0.3);
        my %archive = ( 'ghost-001' => '叫ぶ亡霊', 'ghost-002' => '禁断の肖像画' );
        return exists $archive{$image_id}
            ? { success => 1, content => $archive{$image_id} . "(アーカイブ版)", resolution => '8K' }
            : { success => 0, reason => 'Not found' };
    }
}

# === Remote Proxy ===
package RemoteProxy {
    use Moo;

    has image_id => ( is => 'ro', required => 1 );
    has name => ( is => 'ro', required => 1 );
    has archive_client => ( is => 'ro', default => sub { ArchiveClient->new } );
    has _cached => ( is => 'rw' );

    sub render ($self) { "👻 " . $self->name . " [リモート]" }

    sub render_full ($self) {
        return $self->_cached if defined $self->_cached;
        my $resp = $self->archive_client->fetch_image($self->image_id);
        return $resp->{success}
            ? do { my $r = "🖼️ $resp->{content} [$resp->{resolution}] (remote)"; $self->_cached($r); $r }
            : "❌ 取得失敗: " . $self->name . " - " . $resp->{reason};
    }
}

# === ギャラリー ===
package GhostGallery {
    use Moo;

    has images => ( is => 'ro', default => sub { [] } );

    sub add_image ($self, $img) { push @{$self->images}, $img }

    sub show_gallery ($self) {
        say "\n=== 👻 ゴーストギャラリー ===\n";
        my $i = 1; say "$i. " . $_->render and $i++ for @{$self->images};
        say "\n============================\n";
    }

    sub view_image ($self, $idx) {
        my $img = $self->images->[$idx - 1];
        say "\n🔍 " . ($img ? $img->render_full : "not found") if $img;
    }
}

# === メイン ===
package main {
    my $client = ArchiveClient->new;
    my $gallery = GhostGallery->new;

    $gallery->add_image(GhostImage->new(name => '消えた家族写真'));
    $gallery->add_image(RemoteProxy->new(image_id => 'ghost-001', name => '叫ぶ亡霊', archive_client => $client));
    $gallery->add_image(RemoteProxy->new(image_id => 'ghost-002', name => '禁断の肖像画', archive_client => $client));

    $gallery->show_gallery;
    $gallery->view_image(1);
    $gallery->view_image(2);
    $gallery->view_image(2);  # キャッシュ

    $client->is_online(0);
    $gallery->view_image(2);  # オフラインでもキャッシュで動作
    $gallery->view_image(3);  # キャッシュなし→失敗
}
