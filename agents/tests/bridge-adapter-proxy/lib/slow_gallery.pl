#!/usr/bin/env perl
# 第6回: 画像の読み込みが重い！
# slow_gallery.pl - 全件ロードで遅延問題を体験

use v5.36;
use warnings;

# 重い画像読み込みをシミュレート
package WhiskyImage {
    use Moo;

    has id       => (is => 'ro',   required => 1);
    has filename => (is => 'ro',   required => 1);
    has data     => (is => 'lazy', builder  => '_load_image');

    sub _load_image($self) {
        my $id = $self->id;
        say "  [!] 画像をロード中: $self->{filename} (これは重い処理...)";
        sleep 1;    # 1秒かかる重い処理をシミュレート
        return "IMAGE_DATA_FOR_$id";
    }

    sub BUILD($self, $args) {

        # 生成時に即座にロードしてしまう（問題）
        $self->data;
    }
}

# 画像ギャラリー（問題版：全件ロード）
package SlowGallery {
    use Moo;

    has images => (is => 'ro', default => sub { [] });

    sub load_all($self, @image_ids) {
        say "\n=== ギャラリー初期化開始 ===";
        say "画像を全件ロードします...（N件 × 1秒 = N秒かかる！）\n";

        for my $id (@image_ids) {
            my $img = WhiskyImage->new(
                id       => $id,
                filename => "whisky_$id.jpg",
            );
            push $self->images->@*, $img;
        }

        say "\n=== ギャラリー初期化完了 ===\n";
    }

    sub show_thumbnail($self, $id) {
        my ($img) = grep { $_->id eq $id } $self->images->@*;
        return unless $img;
        say "サムネイル表示: $img->{filename}";
    }
}

# メイン処理
say "=== 遅延問題デモ ===";
say "3件の画像をロードするだけで3秒かかります...\n";

my $gallery = SlowGallery->new;
$gallery->load_all(1, 2, 3);

say "ユーザーが見たいのは1件目だけなのに、全件ロードしてしまった！";
say "";

$gallery->show_thumbnail(1);

say "\n=== 問題点 ===";
say "- 初期化時に全件ロード → 起動が遅い";
say "- ユーザーが見ない画像もロード → 無駄";
say "- N件あれば N秒かかる → スケールしない";
say "- 解決策: 必要な時だけロードする（遅延ロード）";
