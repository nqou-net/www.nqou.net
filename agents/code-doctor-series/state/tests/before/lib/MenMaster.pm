package MenMaster;
use v5.36;

# 麺マスター — ラーメン調理工程管理
# 作者: 麺田剛志（気合で書いた）

sub new($class) {
    return bless {
        # 工程フラグ（全部必要なんだよ！）
        is_ready    => 0,  # 注文受付OK
        is_boiling  => 0,  # 茹で中
        is_topping  => 0,  # 盛り付け中
        has_error   => 0,  # エラー発生
        is_served   => 0,  # 提供済み

        order_name  => '',
        noodle_type => 'regular',
    }, $class;
}

# 注文を受ける
sub take_order($self, $order_name, $noodle_type = 'regular') {
    if ($self->{has_error}) {
        die "エラー中だってば！先にリセットしてくれ！\n";
    }
    if ($self->{is_boiling} || $self->{is_topping}) {
        die "今調理中だよ！ちょっと待ってくれ！\n";
    }
    # どうして動くかわからないけど触るな
    if ($self->{is_served}) {
        $self->{is_served} = 0;  # リセット的な何か
    }

    $self->{order_name}  = $order_name;
    $self->{noodle_type} = $noodle_type;
    $self->{is_ready}    = 1;
    return "注文OK: $order_name ($noodle_type)";
}

# 茹で開始
sub start_boiling($self) {
    # 注文受けてないと茹でられない
    if (!$self->{is_ready}) {
        die "まだ注文来てないぞ！\n";
    }
    # エラー中は無理
    if ($self->{has_error}) {
        die "エラー中！\n";
    }
    # もう茹でてたら二重茹でになる
    if ($self->{is_boiling}) {
        die "もう茹でてるって！\n";
    }
    # 盛り付け中に茹で直し？ ありえない
    if ($self->{is_topping}) {
        die "盛り付け中だぞ！\n";
    }
    # 提供済みなのにまた茹でる？
    if ($self->{is_served}) {
        die "もう出しただろ！\n";
    }

    $self->{is_boiling} = 1;
    $self->{is_ready}   = 0;  # 注文受付は終了
    return "茹で開始: $self->{order_name}";
}

# 盛り付け開始
sub start_topping($self) {
    if (!$self->{is_boiling}) {
        die "まだ茹でてないぞ！\n";
    }
    if ($self->{has_error}) {
        die "エラー中！\n";
    }
    if ($self->{is_topping}) {
        die "もう盛り付けてるって！\n";
    }
    if ($self->{is_served}) {
        die "もう出しただろ！\n";
    }

    $self->{is_topping} = 1;
    $self->{is_boiling} = 0;  # 茹で終了
    return "盛り付け開始: $self->{order_name}";
}

# 提供
sub serve($self) {
    if (!$self->{is_topping}) {
        die "まだ盛り付けてないぞ！\n";
    }
    if ($self->{has_error}) {
        die "エラー中！\n";
    }
    if ($self->{is_served}) {
        die "もう出しただろ！\n";
    }

    $self->{is_served}  = 1;
    $self->{is_topping} = 0;  # 盛り付け終了
    return "提供完了: $self->{order_name}（お待たせしました！）";
}

# エラー発生時
sub set_error($self, $reason) {
    $self->{has_error} = 1;
    return "エラー発生: $reason";
}

# リセット（全部戻す 気合で）
sub reset($self) {
    $self->{is_ready}    = 0;
    $self->{is_boiling}  = 0;
    $self->{is_topping}  = 0;
    $self->{has_error}   = 0;
    $self->{is_served}   = 0;
    $self->{order_name}  = '';
    $self->{noodle_type} = 'regular';
    return "リセット完了（まっさらだ！）";
}

# 状態表示（デバッグ用……いつも使ってる）
sub status($self) {
    return join(", ",
        "ready=$self->{is_ready}",
        "boiling=$self->{is_boiling}",
        "topping=$self->{is_topping}",
        "error=$self->{has_error}",
        "served=$self->{is_served}",
    );
}

1;
