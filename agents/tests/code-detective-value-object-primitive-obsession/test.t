use strict;
use warnings;
use lib 'lib';
use Test::More;
use JSON::MaybeXS;

use_ok('LegacyUser');
use_ok('RefactoredUser');
use_ok('User::Id');
use_ok('User::Age');
use_ok('User::PhoneNumber');

subtest 'レガシーな暗黙の型変換の問題（Before）' => sub {
    my $json_str = LegacyUser::generate_json();
    my $decoded = decode_json($json_str);

    # JSON::PP や JSON::XS の出力文字列を確認する（ここでは型のブレを確認）
    like($json_str, qr/"age":26/, "ageは数値として出力される");
    
    # 文字列結合されたidは文字列として出力される「こともある」（JSONモジュールのバックエンド依存）
    # JSON::PPでは文字列化されるが、Cxsなどでは元の数値フラグを維持する場合があるため、
    # どちらかの型にブレている（不安定である）こと自体を確認する
    ok($json_str =~ /"id":"12345"/ || $json_str =~ /"id":12345/, "idは文字列結合によって型がブレる可能性がある（不安定）");
    
    # レガシーな実装では期待される型がブレることがある、という実証
};

subtest 'Value Objectによる型の保証（After）' => sub {
    my $json_str = RefactoredUser::generate_json();
    my $decoded = decode_json($json_str);
    
    # 出力されたJSON文字列が期待通りの型になっているか確認
    like($json_str, qr/"age":25/, "ageは確実に数値として出力される");
    like($json_str, qr/"id":12345/, "idは確実に数値として出力される");
    like($json_str, qr/"phone":"09012345678"/, "phoneは確実に文字列として出力される");
};

subtest 'Value Objectのバリデーション機能' => sub {
    eval { User::Age->new(value => -1) };
    like($@, qr/Age must be positive/, "不正な年齢は生成時に弾かれる");

    eval { User::PhoneNumber->new(value => '090-1234-5678') };
    like($@, qr/Invalid phone number/, "不正な形式の電話番号は生成時に弾かれる");
};

done_testing();
