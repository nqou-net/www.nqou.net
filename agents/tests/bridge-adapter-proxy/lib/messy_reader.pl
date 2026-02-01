#!/usr/bin/env perl
# 第2回: JSONも読みたい！でも形式が違う
# messy_reader.pl - if/else地獄版

use v5.36;
use warnings;
use JSON::PP;

# CSVデータ
my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
CSV

# JSONデータ（構造が異なる！）
my $json_data = <<'JSON';
{
    "whiskies": [
        {
            "whisky_id": "W002",
            "whisky_name": "ラフロイグ10年",
            "origin": { "country": "スコットランド", "region": "アイラ" },
            "specs": { "age_years": 10, "alcohol_percentage": 40 },
            "tasting_notes": {
                "aroma": "強烈なピート",
                "taste": "スモーキーで塩辛い",
                "after": "力強くドライ"
            },
            "score": 88
        }
    ]
}
JSON

# データ形式を判定して読み込み（if/else地獄の始まり）
sub read_whisky_data($format, $data) {
    my @whiskies;

    if ($format eq 'csv') {
        my @lines = split /\n/, $data;
        shift @lines;    # ヘッダー除去
        for my $line (@lines) {
            next unless $line =~ /\S/;
            my @f = split /,/, $line;
            push @whiskies,
                {
                id     => $f[0],
                name   => $f[1],
                region => $f[2],
                age    => $f[3],
                abv    => $f[4],
                nose   => $f[5],
                palate => $f[6],
                finish => $f[7],
                rating => $f[8],
                };
        }
    }
    elsif ($format eq 'json') {
        my $obj = decode_json($data);
        for my $w ($obj->{whiskies}->@*) {

            # JSONの構造がCSVと全く違う！変換が必要
            push @whiskies,
                {
                id     => $w->{whisky_id},
                name   => $w->{whisky_name},
                region => $w->{origin}{region},
                age    => $w->{specs}{age_years},
                abv    => $w->{specs}{alcohol_percentage},
                nose   => $w->{tasting_notes}{aroma},
                palate => $w->{tasting_notes}{taste},
                finish => $w->{tasting_notes}{after},
                rating => $w->{score},
                };
        }
    }

    # TODO: XMLも追加したい... elsif ($format eq 'xml') { ... }
    # TODO: 外部APIも追加したい... elsif ($format eq 'api') { ... }
    else {
        die "未対応のフォーマット: $format";
    }

    return @whiskies;
}

# 出力もフォーマットごとに分岐（さらにif/else地獄）
sub display_whisky($whisky, $style) {
    if ($style eq 'simple') {
        say "【$whisky->{name}】$whisky->{region} / $whisky->{rating}点";
    }
    elsif ($style eq 'detailed') {
        say "【$whisky->{name}】";
        say "  産地: $whisky->{region} / 熟成: $whisky->{age}年";
        say "  香り: $whisky->{nose}";
        say "  味わい: $whisky->{palate}";
        say "  余韻: $whisky->{finish}";
        say "  評価: $whisky->{rating}/100";
    }

    # TODO: pro スタイルも追加... elsif ($style eq 'pro') { ... }
    else {
        die "未対応のスタイル: $style";
    }
}

# メイン処理
say "=== messy_reader: if/else地獄デモ ===\n";

say "[CSVから読み込み]";
my @csv_whiskies = read_whisky_data('csv', $csv_data);
display_whisky($_, 'detailed') for @csv_whiskies;

say "\n[JSONから読み込み]";
my @json_whiskies = read_whisky_data('json', $json_data);
display_whisky($_, 'detailed') for @json_whiskies;

say "\n=== 問題点 ===";
say "- 新しいフォーマット追加のたびにif/elseが増える";
say "- 各フォーマットの変換ロジックがread_whisky_dataに集中";
say "- データ構造の違いを吸収するコードが散乱";
say "- テストが困難、拡張性が低い";
