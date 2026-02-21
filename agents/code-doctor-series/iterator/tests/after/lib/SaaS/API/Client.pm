package SaaS::API::Client;
use v5.36;

sub new($class) {
    bless {
        calls => 0,    # モック用のカウンタ
    }, $class;
}

# 100件ずつ返すモックAPI（Before版と同一）
sub get_users($self, $page = 1) {
    $self->{calls}++;

    # 全1025件のデータをシミュレート
    my $total_items = 1025;
    my $per_page    = 100;
    my $start_idx   = ($page - 1) * $per_page;

    return {items => [], next_page => undef} if $start_idx >= $total_items;

    my $end_idx = $start_idx + $per_page - 1;
    $end_idx = $total_items - 1 if $end_idx >= $total_items;

    my @items = map { {id => $_ + 1, name => "User " . ($_ + 1)} } ($start_idx .. $end_idx);

    my $next_page = ($end_idx < $total_items - 1) ? $page + 1 : undef;

    return {
        items     => \@items,
        next_page => $next_page,
    };
}

# 【処方領域】
# APIのページネーション状態を内部に秘匿し、1件ずつ返すイテレータファクトリ
sub enumerate_users($self) {
    my $current_page = 1;
    my @buffer       = ();
    my $is_eof       = 0;

    # クロージャ（状態をカプセル化したサブルーチンリファレンス）を返す
    return sub {

        # バッファが空で、かつまだ終端に達していないなら次ページを取得
        if (@buffer == 0 && !$is_eof) {
            my $res = $self->get_users($current_page);

            if (scalar $res->{items}->@* == 0) {
                $is_eof = 1;    # これ以上データなし
            }
            else {
                push @buffer, $res->{items}->@*;

                if (defined $res->{next_page}) {
                    $current_page = $res->{next_page};
                }
                else {
                    $is_eof = 1;    # 最後まで取得完了
                }
            }
        }

        # バッファから1件ずつ取り出して返す
        return shift @buffer;    # 空ならundefが返る
    };
}

1;
