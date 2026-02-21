package SubjectPoller;
use v5.36;
use utf8;
use experimental 'signatures';

# カタブツインフラエンジニアが書いた、愚直なポーリングとハードコード通知の塊
sub new ($class, $target_api) {
    bless {
        target_api    => $target_api,
        last_status   => 'normal',
        request_count => 0,
        notifications => [],
    }, $class;
}

sub check_once ($self) {

    # 相手のインフラ（推しのサーバー）に負荷をかける（Pull型）
    $self->{request_count}++;
    my $current_status = $self->{target_api}->fetch_status();

    # 状態が変わっていたら、各所へ通知（ハードコードでガチガチの密結合）
    if ($current_status ne $self->{last_status}) {

        # 通知先が増えるたびにここを修正・リリースしなきゃいけない
        push $self->{notifications}->@*, "[LINE連携] ピュア・バイナリ: $current_status";
        push $self->{notifications}->@*, "[Discord Bot] \@everyone 状態更新: $current_status";
        push $self->{notifications}->@*, "[パトランプ] 回転開始！ ($current_status)";

        $self->{last_status} = $current_status;
    }
}

sub get_notifications ($self) {
    return $self->{notifications};
}

# 相手側のシステム（シミュレート用）
package FakeIdolApi;
use v5.36;
use utf8;
use experimental 'signatures';

sub new ($class) {
    bless {status => 'normal'}, $class;
}

# 管理者側で更新
sub update_status ($self, $status) {
    $self->{status} = $status;
}

# REST API的なエンドポイントのつもり
sub fetch_status ($self) {
    return $self->{status};
}

1;
