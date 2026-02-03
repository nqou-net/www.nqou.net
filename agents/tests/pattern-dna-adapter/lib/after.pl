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

    has controller => (
        is       => 'ro',
        does     => 'Controller',
        required => 1,
    );

    sub run_loop {
        my ($self) = @_;
        my $input = $self->controller->get_input;

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

    # 0x01: Aボタン(攻撃)
    # 0x02: Bボタン(ジャンプ)
    sub poll_device {
        my ($self) = @_;
        return 0x02;    # ジャンプ
    }
}

# --- 4. アダプター（今回の処方箋） ---
package LegacyAdapter {
    use Moo;
    with 'Controller';    # インターフェース適合

    # 委譲先（Adaptee）を保持
    has adaptee => (
        is       => 'ro',
        required => 1,
    );

    sub get_input {
        my ($self) = @_;

        # 1. レガシーAPIを呼び出す
        my $raw_data = $self->adaptee->poll_device;

        # 2. 最新APIに変換する（Adapterの責務）
        if ($raw_data & 0x02) {
            return {action => 'jump'};
        }
        elsif ($raw_data & 0x01) {
            return {action => 'attack'};
        }
        else {
            return {action => 'wait'};
        }
    }
}

# --- 5. メイン処理（解決版） ---
package main;

# コントローラー（Adaptee）
my $legacy_pad = LegacyController->new;

# アダプターを経由して接続
my $adapter = LegacyAdapter->new(adaptee => $legacy_pad);

# これなら刺さる！
my $game = ModernGame->new(controller => $adapter);

print "接続成功: ";
$game->run_loop;
