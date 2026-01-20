#!/usr/bin/env perl
use v5.36;
use JSON::PP;

# アドレス帳データ
my @contacts = (
    { name => '田中太郎', email => 'tanaka@example.com', phone => '090-1234-5678' },
    { name => '鈴木花子', email => 'suzuki@example.com', phone => '080-2345-6789' },
    { name => '佐藤次郎', email => 'sato@example.com',   phone => '070-3456-7890' },
);

# コマンドライン引数から形式を取得（デフォルトはcsv）
my $format = $ARGV[0] // 'csv';

# 形式に応じて出力を切り替え
if ($format eq 'csv') {
    # CSV形式で出力
    say "name,email,phone";
    for my $contact (@contacts) {
        say "$contact->{name},$contact->{email},$contact->{phone}";
    }
}
elsif ($format eq 'json') {
    # JSON形式で出力
    my $json = JSON::PP->new->pretty->encode(\@contacts);
    print $json;
}
else {
    die "未対応の形式です: $format\n";
}
