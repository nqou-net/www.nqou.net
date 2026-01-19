#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Mojo::UserAgent（Mojoliciousに含まれる）

use v5.36;
use Mojo::UserAgent;
use FindBin qw($RealBin);

my $ua = Mojo::UserAgent->new;

# 天気予報サイトから取得
my $file = "$RealBin/html/sample_weather.html";
my $res = $ua->get("file://$file")->result;

if ($res->is_success) {
    my $dom = $res->dom;

    say "=== 週間天気予報 ===";
    # 天気予報の各行をループ
    for my $row ($dom->find('tr.day-forecast')->each) {
        my $date = $row->at('td.date')->text;
        my $weather = $row->at('td.weather')->text;
        my $temp = $row->at('td.temp')->text;
        say "$date: $weather ($temp)";
    }

    # 結果をファイルに保存
    open my $fh, '>', "$RealBin/weather_result.txt" or die "Cannot open: $!";
    for my $row ($dom->find('tr.day-forecast')->each) {
        my $date = $row->at('td.date')->text;
        my $weather = $row->at('td.weather')->text;
        my $temp = $row->at('td.temp')->text;
        print $fh "$date: $weather ($temp)\n";
    }
    close $fh;
    say "結果を weather_result.txt に保存しました";
} else {
    say "取得失敗: " . $res->message;
}
