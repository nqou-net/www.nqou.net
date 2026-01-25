#!/usr/bin/env perl
# 第3回 Adapterパターンのテストコード
use v5.36;

# 天気サービスの共通インターフェース（Role）
package WeatherAdapter::Role {
    use v5.36;
    use Moo::Role;

    requires 'get_weather';
    requires 'name';

    sub show_weather ($self, $city) {
        my $weather = $self->get_weather($city);
        if ($weather) {
            say "$weather->{city}: $weather->{condition}（気温 $weather->{temperature}℃、湿度 $weather->{humidity}%）";
        }
        else {
            say "$city: データを取得できませんでした";
        }
    }
}

# OpenWeatherMap用Adapter
package WeatherAdapter::OpenWeatherMap {
    use v5.36;
    use Moo;

    has name => (is => 'ro', default => 'OpenWeatherMap');

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        my %mock_data = (
            'Tokyo'   => { name => 'Tokyo',   main => { temp => 25.5, humidity => 60 }, weather => [{ description => '晴れ' }] },
            'Osaka'   => { name => 'Osaka',   main => { temp => 27.2, humidity => 65 }, weather => [{ description => '曇り' }] },
            'Sapporo' => { name => 'Sapporo', main => { temp => 18.3, humidity => 70 }, weather => [{ description => '雨' }] },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        my $data = $self->_get_raw_data($city);
        return unless $data;
        return {
            city        => $data->{name},
            temperature => $data->{main}{temp},
            humidity    => $data->{main}{humidity},
            condition   => $data->{weather}[0]{description},
        };
    }
}

# WeatherStack用Adapter
package WeatherAdapter::WeatherStack {
    use v5.36;
    use Moo;

    has name => (is => 'ro', default => 'WeatherStack');

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        my %mock_data = (
            'Tokyo'   => { location => { name => 'Tokyo' },   current => { temperature => 26, humidity => 58, weather_descriptions => ['Sunny'] } },
            'Osaka'   => { location => { name => 'Osaka' },   current => { temperature => 28, humidity => 63, weather_descriptions => ['Cloudy'] } },
            'Sapporo' => { location => { name => 'Sapporo' }, current => { temperature => 19, humidity => 68, weather_descriptions => ['Rain'] } },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        my $data = $self->_get_raw_data($city);
        return unless $data;
        return {
            city        => $data->{location}{name},
            temperature => $data->{current}{temperature},
            humidity    => $data->{current}{humidity},
            condition   => $data->{current}{weather_descriptions}[0],
        };
    }
}

# メイン処理
package main {
    use v5.36;

    say "=== 天気予報アグリゲーター（Adapter版） ===";
    say "";

    # 各Adapterを作成
    my $owm = WeatherAdapter::OpenWeatherMap->new;
    my $ws  = WeatherAdapter::WeatherStack->new;

    say "--- OpenWeatherMap ---";
    $owm->show_weather('Tokyo');
    $owm->show_weather('Osaka');
    $owm->show_weather('Sapporo');

    say "";
    say "--- WeatherStack ---";
    $ws->show_weather('Tokyo');
    $ws->show_weather('Osaka');
    $ws->show_weather('Sapporo');

    say "";
    say "--- 統一インターフェースで扱う ---";
    my @adapters = ($owm, $ws);
    for my $adapter (@adapters) {
        my $weather = $adapter->get_weather('Tokyo');
        say "Tokyo: $weather->{temperature}℃";
    }
}
