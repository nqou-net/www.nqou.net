#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# Before: Shotgun Surgery（散弾銃手術）の例
#
# StockManager が在庫更新時に、メール送信・ログ書き込み・ダッシュボード更新を
# すべて直接呼び出している。新しい通知手段を追加するたびに update_stock を
# 修正する必要があり、修正のたびに既存の通知が壊れるリスクがある。
# ==============================================================================

package StockManager {
    use Moo;

    sub update_stock ($self, $item, $quantity) {
        # 在庫の更新（ここではシミュレーション）
        my $message = "Stock updated: $item => $quantity";

        # --- ここから先が「散弾銃」 ---
        # 通知手段ごとに直書き。追加・変更のたびにこのメソッドを触る。

        # メール通知
        my $email = $self->_send_email($item, $quantity);

        # ログ記録
        my $log = $self->_write_log($item, $quantity);

        # ダッシュボード更新
        my $dashboard = $self->_refresh_dashboard($item, $quantity);

        return {
            message   => $message,
            email     => $email,
            log       => $log,
            dashboard => $dashboard,
        };
    }

    sub _send_email ($self, $item, $quantity) {
        return "[EMAIL] $item is now $quantity";
    }

    sub _write_log ($self, $item, $quantity) {
        return "[LOG] $item: quantity changed to $quantity";
    }

    sub _refresh_dashboard ($self, $item, $quantity) {
        return "[DASHBOARD] Refreshed: $item ($quantity)";
    }
}

# 動作確認
if (!caller) {
    my $manager = StockManager->new;
    my $result  = $manager->update_stock('Keyboard', 150);

    say $result->{message};
    say $result->{email};
    say $result->{log};
    say $result->{dashboard};
}

1;
