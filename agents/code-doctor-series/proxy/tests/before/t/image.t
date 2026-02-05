#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Image;

subtest '画像一覧表示のシミュレーション' => sub {
    my @files = qw(photo1.jpg photo2.jpg photo3.jpg);

    # 問題: 一覧表示のためにサムネイルが欲しいだけなのに...
    say "--- 3枚のサムネイルを表示しようとしています ---";

    my @images;
    for my $file (@files) {

        # この時点でフルサイズ読み込みが発生してしまう！
        push @images, Image->new($file);
    }

    # サムネイルを表示
    for my $img (@images) {
        my $thumb = $img->get_thumbnail();
        ok defined $thumb, "サムネイル取得: $thumb";
    }

    say "--- 実際に1枚だけクリックして詳細表示 ---";
    my $full = $images[0]->display();
    ok defined $full, "フル画像取得";

    # 結果: 3枚すべてがフルサイズで読み込まれた
    # （上のログを見ると3回 "Loading full image" が出ている）
};

done_testing;
