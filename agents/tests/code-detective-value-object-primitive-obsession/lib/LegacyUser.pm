package LegacyUser;

use strict;
use warnings;
use JSON::MaybeXS;

sub generate_json {
    # 実際はDBなどから取得するが、ここではハッシュリファレンスとして定義
    my $user = {
        id    => 12345,         # id は auto_increment の数値として取得されることが多い
        age   => '25',          # DBドライバによっては文字列として取得される
        phone => '09012345678', # 電話番号はゼロから始まるため文字列
    };

    # 何らかの判定や処理で数値として扱われると、Perl内部で数値フラグが立つ
    $user->{age} += 1;

    # id（数値）を文字列結合すると、文字列フラグが立ち、数値フラグよりも優先されることがある
    my $log_msg = "User ID: " . $user->{id};

    # JSONにシリアライズ
    # JSONモジュールは内部フラグを見て型を決めるため、
    # 直前の処理によって型の推論結果が変わってしまう
    my $json = encode_json($user);
    
    return $json;
}

1;
