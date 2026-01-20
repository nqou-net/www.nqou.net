#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std' => ':encoding(UTF-8)';
use FindBin;
use lib "$FindBin::Bin/lib";

# 第5回の完成コード - Adapterパターン実装例

use WeatherService;
use OldWeatherAPI;
use OldWeatherAdapter;
use ForeignWeatherService;
use ForeignWeatherAdapter;

say "╔══════════════════════════════════════════════════════════╗";
say "║     天気情報ツール - Adapterパターン実装例              ║";
say "╚══════════════════════════════════════════════════════════╝";
say "";

# 3つのサービスを準備（Adapterでラップ）
my @services = (
    WeatherService->new,
    OldWeatherAdapter->new(old_api => OldWeatherAPI->new),
    ForeignWeatherAdapter->new(foreign_service => ForeignWeatherService->new),
);

# 各サービスの情報を表示（統一インターフェースで処理）
for my $service (@services) {
    say "■ " . $service->name;
    say "-" x 40;

    if ($service->name eq '海外天気サービス') {
        $service->show_weather('ニューヨーク');
        $service->show_weather('ロンドン');
        $service->show_weather('パリ');
    } else {
        $service->show_weather('東京');
        $service->show_weather('大阪');
    }

    say "";
}

say "━" x 60;
say "Adapterパターンにより、異なるインターフェースを持つ";
say "3つのサービスを統一的に扱えるようになりました。";
