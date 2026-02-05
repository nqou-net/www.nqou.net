#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use External::ComplexSystem;

# Patient's Code: "Directly calling everything"
# 症状: 外部システムの詳細な手順がクライアントコードに漏れ出している。
# 何か一つ手順を間違えたり、APIが変わったら即死する。

try_purchase("item_A");
try_purchase("item_B");

sub try_purchase ($item_name) {
    say "Processing purchase for $item_name...";

    # 1. システムの生成
    my $system = External::ComplexSystem->new;

    # 2. 初期化 (これを忘れると動かない)
    $system->initialize_subsystem();

    # 3. パラメータ設定 (マジックナンバーだらけ)
    $system->set_config_param("timeout", 30);
    $system->set_config_param("mode",    "strict");

    # 4. 認証
    my $token = $system->authenticate_user("admin");

    # 5. 接続確立
    $system->establish_connection($token);

    # 6. トランザクション開始
    my $tx = $system->create_transaction();

    # 7. 処理
    $tx->add_item($item_name);

    # 8. コミット
    $tx->commit();

    say "Purchase completed.\n";
}
