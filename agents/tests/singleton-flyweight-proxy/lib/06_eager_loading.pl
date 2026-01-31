#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Time::HiRes qw(time);

# 第6回: 使わない文字もロードしてしまう問題
# 全フォントデータを起動時にロードする非効率な実装

package HeavyFont {
    use Moo;

    has name => (is => 'ro', required => 1);
    has data => (is => 'ro', required => 1);

    # 重い初期化処理をシミュレート
    sub BUILD($self, $args) {

        # 大きなフォントファイルの読み込みをシミュレート
        select(undef, undef, undef, 0.01);    # 10ms待機
    }
}

package EagerFontLoader {
    use Moo;

    has fonts => (is => 'ro', default => sub { {} });

    # 起動時にすべてのフォントをロード（問題のある設計）
    sub BUILD($self, $args) {
        say "フォントを読み込み中...";
        for my $char ('A' .. 'Z', '0' .. '9') {
            my $font = HeavyFont->new(
                name => $char,
                data => "DUMMY_DATA_FOR_$char" x 100,
            );
            $self->fonts->{$char} = $font;
            print ".";
        }
        say " 完了！";
    }

    sub get_font($self, $char) {
        return $self->fonts->{uc $char};
    }
}

package main;

say "=== ASCIIアート・フォントレンダラー v0.6 ===";
say "";

# 起動時間を計測
my $start   = time();
my $loader  = EagerFontLoader->new;
my $elapsed = time() - $start;

say "";
say sprintf("起動時間: %.2f秒", $elapsed);
say "ロードしたフォント数: " . scalar(keys $loader->fonts->%*);
say "";

# 実際に使うのはHELLOだけ
say "「HELLO」を表示するだけなのに...";
my @chars = split //, "HELLO";
say "  使う文字: " . join(", ", @chars) . " (5種類)";
say "  ロード済み: 36種類";
say "";

say "*** 問題発覚 ***";
say "";
say "5種類しか使わないのに、36種類全部をロードしている！";
say "  - 起動が遅い (${elapsed}秒)";
say "  - メモリを無駄に使用";
say "  - 使わない文字のデータまで保持";
say "";
say "→ 必要なときに必要な文字だけロードすればよいのでは？";
