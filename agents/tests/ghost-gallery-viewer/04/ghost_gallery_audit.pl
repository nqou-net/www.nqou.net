#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）
# ファイル名: ghost_gallery_audit.pl

use v5.36;

# === 高解像度アート画像クラス（RealSubject） ===
package GhostImage {
    use Moo;
    use Time::HiRes qw(sleep);

    has name => ( is => 'ro', required => 1 );
    has resolution => ( is => 'ro', default => sub { '8K' } );

    sub BUILD ($self, $args) { sleep(0.2) }
    sub render ($self) { "🖼️ " . $self->name . " [" . $self->resolution . "]" }
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
}

# === Audit Proxy (Logging Proxy) ===
package AuditProxy {
    use Moo;

    has inner_proxy => ( is => 'ro', required => 1 );
    has current_user => ( is => 'rw', default => sub { { name => 'anonymous' } } );
    has log_storage => ( is => 'ro', default => sub { [] } );

    sub name ($self) { $self->inner_proxy->name }

    sub _log ($self, $action) {
        my ($s, $m, $h, $d, $mo, $y) = localtime;
        my $ts = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y+1900, $mo+1, $d, $h, $m, $s);
        push @{$self->log_storage}, {
            timestamp => $ts, user => $self->current_user->{name},
            action => $action, target => $self->name,
        };
        say "[AUDIT] $ts | " . $self->current_user->{name} . " | $action | " . $self->name;
    }

    sub render ($self) { $self->_log('PREVIEW'); $self->inner_proxy->render }
    sub render_full ($self) { $self->_log('VIEW_FULL'); $self->inner_proxy->render_full }
}

# === ギャラリー ===
package GhostGallery {
    use Moo;

    has images => ( is => 'ro', default => sub { [] } );
    has current_user => ( is => 'rw', default => sub { { name => 'ゲスト' } } );
    has audit_log => ( is => 'ro', default => sub { [] } );

    sub add_image ($self, $img) {
        $img = AuditProxy->new(inner_proxy => $img->inner_proxy, log_storage => $self->audit_log)
            if $img->isa('AuditProxy');
        push @{$self->images}, $img;
    }

    sub set_user ($self, $user) {
        $self->current_user($user);
        $_->current_user($user) for grep { $_->isa('AuditProxy') } @{$self->images};
    }

    sub show_gallery ($self) {
        say "\n=== 👻 ゴーストギャラリー ===\nログイン: " . $self->current_user->{name} . "\n";
        my $i = 1; say "$i. " . $_->render and $i++ for @{$self->images};
        say "\n============================\n";
    }

    sub view_image ($self, $idx) {
        my $img = $self->images->[$idx - 1];
        say "\n🔍 " . ($img ? $img->render_full : "not found") if $img;
    }

    sub export_audit_log ($self) {
        say "\n📋 監査ログ\n" . "=" x 60;
        say "$_->{timestamp} | $_->{user} | $_->{action} | $_->{target}" for @{$self->audit_log};
        say "=" x 60 . "\nTotal: " . scalar(@{$self->audit_log});
    }
}

# === メイン ===
package main {
    my $gallery = GhostGallery->new;
    $gallery->add_image(AuditProxy->new(inner_proxy => ImageProxy->new(name => '叫ぶ亡霊')));
    $gallery->add_image(AuditProxy->new(inner_proxy => ImageProxy->new(name => '禁断の肖像画')));

    $gallery->set_user({ name => '田中太郎' });
    $gallery->show_gallery;
    $gallery->view_image(1);

    $gallery->set_user({ name => '山田花子' });
    $gallery->view_image(2);

    $gallery->export_audit_log;
}
