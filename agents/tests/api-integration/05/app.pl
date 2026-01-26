#!/usr/bin/env perl
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
            'Nagoya'  => { name => 'Nagoya',  main => { temp => 26.8, humidity => 62 }, weather => [{ description => '晴れ' }] },
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
            source      => $self->name,
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
            'Sapporo' => { location => { name => 'Sapporo' }, current => { temperature => 19, humidity => 68, weather_descriptions => ['Rain'] } },
            'Sendai'  => { location => { name => 'Sendai' },  current => { temperature => 22, humidity => 65, weather_descriptions => ['Cloudy'] } },
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
            source      => $self->name,
        };
    }
}

# Facade: 複数のAdapterを統合管理
package WeatherFacade {
    use v5.36;
    use Moo;

    has adapters => (
        is       => 'ro',
        required => 1,
    );

    # 天気情報を取得（フォールバック付き）
    sub get_weather ($self, $city) {
        for my $adapter ($self->adapters->@*) {
            my $weather = $adapter->get_weather($city);
            return $weather if $weather;
        }
        return;
    }

    # 便利メソッド: 天気を整形表示
    sub show_weather ($self, $city) {
        my $weather = $self->get_weather($city);
        if ($weather) {
            say "$weather->{city}: $weather->{condition}（気温 $weather->{temperature}℃、湿度 $weather->{humidity}%）[via $weather->{source}]";
        }
        else {
            say "$city: データを取得できませんでした";
        }
    }
}

# メイン処理
package main {
    use v5.36;

    say "=== 天気予報アグリゲーター（Facade版） ===";
    say "";

    # Facadeを作成
    my $facade = WeatherFacade->new(
        adapters => [
            WeatherAdapter::OpenWeatherMap->new,
            WeatherAdapter::WeatherStack->new,
        ],
    );

    # シンプルな呼び出し
    my @cities = qw(Tokyo Osaka Sapporo Nagoya Sendai Fukuoka);

    for my $city (@cities) {
        $facade->show_weather($city);
    }

    say "";
    say "--- 直接get_weatherを使う場合 ---";
    my $weather = $facade->get_weather('Sapporo');
    if ($weather) {
        say "Sapporo の天気データを $weather->{source} から取得しました";
    }
}
