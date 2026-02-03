use v5.34;
use utf8;
binmode STDOUT, ':utf8';

# --- 1. インターフェース定義 ---
package Controller {
    use Moo::Role;
    requires 'get_input';
}

# --- 2. 最新のゲームエンジン ---
package ModernGame {
    use Moo;

    # 最新のコントローラー（インターフェース準拠）しか受け付けない
    has controller => (
        is       => 'ro',
        does     => 'Controller',
        required => 1,
    );

    sub run_loop {
        my ($self) = @_;
        my $input = $self->controller->get_input;

        # inputは構造化データ（ハッシュリファレンス）を期待
        if ($input->{action} eq 'jump') {
            print "ヒーローはジャンプした！\n";
        }
        elsif ($input->{action} eq 'attack') {
            print "ヒーローの攻撃！\n";
        }
        else {
            print "待機中...\n";
        }
    }
}

# --- 3. 伝説のコントローラー（レガシー） ---
package LegacyController {
    use Moo;

    # 昔ながらのビット演算
    # 0x01: Aボタン(攻撃)
    # 0x02: Bボタン(ジャンプ)
    sub poll_device {
        my ($self) = @_;

        # シミュレーション用にランダムな入力を返す
        # ここでは固定で「ジャンプ」を返すことにする
        return 0x02;
    }
}

# --- 4. メイン処理（問題あり） ---
package main;

# 接続しようとするが...
my $legacy_pad = LegacyController->new;

# エラー: ModernGameはControllerロールを持つオブジェクトを期待しているが
# LegacyControllerはそのようなロールを持っておらず、メソッド体系も異なる
# my $game = ModernGame->new(controller => $legacy_pad);
# $game->run_loop;

print "直接接続できません。Adapterが必要です。\n";
