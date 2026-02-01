#!/usr/bin/env perl
# 第1回: まずはCSVから読み込もう
# simple_note.pl - CSV直接読み込み版

use v5.36;
use warnings;

# CSVデータをHEREDOCで定義（実際はファイルから読む）
my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
2,ラフロイグ10年,アイラ,10,40,強烈なピート,スモーキーで塩辛い,力強くドライ,88
3,グレンフィディック12年,スペイサイド,12,40,洋梨とリンゴ,クリーミーで甘い,フレッシュな余韻,85
CSV

# CSVをパースして表示
say "=== ウイスキーテイスティング・ノート ===\n";

my @lines  = split /\n/, $csv_data;
my $header = shift @lines;

for my $line (@lines) {
    next unless $line =~ /\S/;
    my @fields = split /,/, $line;
    my ($id, $name, $region, $age, $abv, $nose, $palate, $finish, $rating) = @fields;

    say "【$name】";
    say "  産地: $region / 熟成: ${age}年 / 度数: ${abv}%";
    say "  香り: $nose";
    say "  味わい: $palate";
    say "  余韻: $finish";
    say "  評価: $rating/100";
    say "";
}

say "=== 読み込み完了 ===";
