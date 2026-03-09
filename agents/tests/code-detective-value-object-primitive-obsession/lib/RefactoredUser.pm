package RefactoredUser;

use strict;
use warnings;
use JSON::MaybeXS;
use User::Id;
use User::Age;
use User::PhoneNumber;

sub generate_json {
    # 実際はDBなどから取得するが、ここではハッシュリファレンスとして定義
    my $user = {
        id    => User::Id->new(value => 12345),
        age   => User::Age->new(value => 25),
        phone => User::PhoneNumber->new(value => '09012345678'),
    };

    # 値として取り出して計算することはできても、
    # オブジェクト自体を誤って変更しようとするとエラー（または意図した挙動）になる
    # 今回の例では内部のvalueはro（読み取り専用）なので変更不可

    # 文字列結合を行なっても、オブジェクト自体の型（クラス）は維持される
    my $log_msg = "User ID: " . $user->{id}->value;

    # JSON化時に convert_blessed を有効にする
    my $coder = JSON::MaybeXS->new(convert_blessed => 1);
    
    # オブジェクトのTO_JSONが呼ばれ、設計者が意図した通りの型で確実に出力される
    my $json = $coder->encode($user);
    
    return $json;
}

1;
