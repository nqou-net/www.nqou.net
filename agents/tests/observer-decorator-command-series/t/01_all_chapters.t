#!/usr/bin/env perl
# テスト: 秘密のメッセンジャー - 各章のコードを個別に実行テスト
use v5.36;
use Test::More;
use FindBin;

my $lib_dir = "$FindBin::Bin/../lib";

# 各章のスクリプトが実行可能かテスト
my @scripts = qw(
    ch01_message_box.pl
    ch02_broken_encryption.pl
    ch03_xor_encryptor.pl
    ch04_base64_decorator.pl
    ch04_timestamp_decorator.pl
    ch05_polling.pl
    ch06_notification_observer.pl
    ch07_inline_history.pl
    ch08_commands.pl
    ch09_secret_messenger.pl
);

for my $script (@scripts) {
    subtest "実行テスト: $script" => sub {
        my $path = "$lib_dir/$script";
        ok -f $path, "ファイルが存在: $script";

        my $output    = `perl $path 2>&1`;
        my $exit_code = $? >> 8;
        is $exit_code, 0, "正常終了: $script";

        # 出力があることを確認
        ok length($output) > 0, "出力あり: $script";
    };
}

done_testing;
