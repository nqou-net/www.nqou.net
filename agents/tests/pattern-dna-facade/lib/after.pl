use v5.34;
use utf8;
binmode STDOUT, ':utf8';

# --- 1. サブシステム（Beforeと同じ定義） ---

package Device::Light {
    use Moo;
    sub turn_on        { print "[照明] 点灯しました\n" }
    sub turn_off       { print "[照明] 消灯しました\n" }
    sub set_brightness { my ($self, $v) = @_; print "[照明] 明るさを $v% に設定\n" }
}

package Device::AirConditioner {
    use Moo;
    sub on       { print "[エアコン] 電源ON\n" }
    sub off      { print "[エアコン] 電源OFF\n" }
    sub set_mode { my ($self, $m) = @_; print "[エアコン] モードを $m に変更\n" }
    sub set_temp { my ($self, $t) = @_; print "[エアコン] 温度を ${t}度に設定\n" }
}

package Device::SmartLock {
    use Moo;
    sub lock   { print "[鍵] 施錠しました\n" }
    sub unlock { print "[鍵] 解錠しました\n" }
}

# --- 2. Facade（コードドクターの処方箋） ---
# 複雑なサブシステムの操作を「意味のある単位」にまとめる

package SmartHomeFacade {
    use Moo;

    # サブシステムを内部に持つ
    has light => (is => 'ro', default => sub { Device::Light->new });
    has ac    => (is => 'ro', default => sub { Device::AirConditioner->new });
    has lock  => (is => 'ro', default => sub { Device::SmartLock->new });

    # 外部に提供するシンプルなインターフェース

    sub leave_home {
        my $self = shift;
        print "--- Facade: 外出シーケンス開始 ---\n";

        # 複雑な手順はFacadeが引き受ける
        $self->light->turn_off;
        $self->ac->off;
        $self->lock->lock;

        print "--- Facade: 外出準備完了 ---\n";
    }

    sub arrive_home {
        my $self = shift;
        print "--- Facade: 帰宅シーケンス開始 ---\n";

        $self->lock->unlock;
        $self->light->turn_on;
        $self->light->set_brightness(100);
        $self->ac->on;
        $self->ac->set_mode('warm');
        $self->ac->set_temp(24);

        print "--- Facade: おかえりなさい ---\n";
    }
}

# --- 3. クライアント（アプリのUI層） ---
# 改善点: サブシステムの詳細を知る必要がなくなり、Facadeを呼ぶだけになった

package SmartHomeApp {
    use Moo;

    # 依存するのはFacadeのみ
    has home_api => (is => 'ro', default => sub { SmartHomeFacade->new });

    sub on_leave_button_click {
        my $self = shift;
        print "\n=== 外出ボタンが押されました ===\n";

        # たった1行！
        $self->home_api->leave_home;

        print "=> UI処理完了\n";
    }

    sub on_arrive_button_click {
        my $self = shift;
        print "\n=== 帰宅ボタンが押されました ===\n";

        $self->home_api->arrive_home;

        print "=> UI処理完了\n";
    }
}

# --- 実行 ---
package main;

my $app = SmartHomeApp->new;

# 外出！
$app->on_leave_button_click;

# 帰宅！
$app->on_arrive_button_click;
