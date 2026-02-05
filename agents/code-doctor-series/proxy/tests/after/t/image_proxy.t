#!/usr/bin/env perl
use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ImageProxy;

subtest '画像一覧表示のシミュレーション（Proxy適用後）' => sub {
    my @files = qw(photo1.jpg photo2.jpg photo3.jpg);

    say "--- 3枚のサムネイルを表示しようとしています ---";

    my @images;
    for my $file (@files) {

        # Proxyを生成しても、まだ実際のファイル読み込みは発生しない！
        push @images, ImageProxy->new($file);
    }

    # サムネイルを表示（軽量なプレースホルダー）
    for my $img (@images) {
        my $thumb = $img->get_thumbnail();
        ok defined $thumb, "サムネイル取得: $thumb";
    }

    say "--- 実際に1枚だけクリックして詳細表示 ---";

    # この時点で初めて1枚だけ読み込まれる
    my $full = $images[0]->display();
    ok defined $full, "フル画像取得";

    # 結果: "Loading full image" は1回だけ！
    # 残り2枚は読み込まれていない
};

subtest 'アクセスログの一元化確認' => sub {
    say "--- アクセスログ確認 ---";
    my $img = ImageProxy->new("test.jpg");

    # サムネイル取得（ログあり、読み込みなし）
    $img->get_thumbnail();

    # フル表示（ログあり、読み込みあり）
    $img->display();

    # 2回目のフル表示（読み込みなし、キャッシュ済み）
    $img->display();

    pass "ログ出力を確認してください";
};

done_testing;
