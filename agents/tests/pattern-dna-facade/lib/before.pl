use v5.34;
use utf8;
binmode STDOUT, ':utf8';

# --- 1. サブシステム（バラバラのデバイスAPI） ---

package Device::Light {
    use Moo;

    sub turn_on {
        my $self = shift;
        print "[照明] 点灯しました\n";
    }

    sub turn_off {
        my $self = shift;
        print "[照明] 消灯しました\n";
    }

    sub set_brightness {
        my ($self, $level) = @_;
        print "[照明] 明るさを $level% に設定\n";
    }
}

package Device::AirConditioner {
    use Moo;

    sub on {
        my $self = shift;
        print "[エアコン] 電源ON\n";
    }

    sub off {
        my $self = shift;
        print "[エアコン] 電源OFF\n";
    }

    sub set_mode {
        my ($self, $mode) = @_;
        print "[エアコン] モードを $mode に変更\n";
    }

    sub set_temp {
        my ($self, $temp) = @_;
        print "[エアコン] 温度を ${temp}度に設定\n";
    }
}

package Device::SmartLock {
    use Moo;

    sub lock {
        my $self = shift;
        print "[鍵] 施錠しました\n";
    }

    sub unlock {
        my $self = shift;
        print "[鍵] 解錠しました\n";
    }
}

# --- 2. クライアント（アプリのUI層） ---
# 症状: サブシステム露出過多症
# 複数のデバイスを個別に操作しなければならず、ロジックが複雑化している

package SmartHomeApp {
    use Moo;

    has light => (is => 'ro', default => sub { Device::Light->new });
    has ac    => (is => 'ro', default => sub { Device::AirConditioner->new });
    has lock  => (is => 'ro', default => sub { Device::SmartLock->new });

    sub on_leave_button_click {
        my $self = shift;
        print "\n=== 外出ボタンが押されました ===\n";

        # 1. 照明を消す
        $self->light->turn_off;

        # 2. エアコンを消す（冬場はつけっぱなしかもしれないが...）
        $self->ac->off;

        # 3. 鍵をかける
        $self->lock->lock;

        # UIへのフィードバック
        print "=> 外出モード完了（面倒くさい手順でした...）\n";
    }

    sub on_arrive_button_click {
        my $self = shift;
        print "\n=== 帰宅ボタンが押されました ===\n";

        # 1. 鍵を開ける
        $self->lock->unlock;

        # 2. 照明をつける
        $self->light->turn_on;
        $self->light->set_brightness(100);

        # 3. エアコンをつける
        $self->ac->on;
        $self->ac->set_mode('warm');
        $self->ac->set_temp(24);

        print "=> 帰宅モード完了（デバイスごとにメソッド名も違って大変...）\n";
    }
}

# --- 実行 ---
package main;

my $app = SmartHomeApp->new;

# 外出！
$app->on_leave_button_click;

# 帰宅！
$app->on_arrive_button_click;
