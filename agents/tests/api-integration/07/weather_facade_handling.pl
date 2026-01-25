#!/usr/bin/env perl
use v5.36;
use Try::Tiny;

# 天気サービスの共通インターフェース（Role）
package WeatherAdapter::Role {
    use v5.36;
    use Moo::Role;

    requires 'get_weather';
    requires 'name';
}

# OpenWeatherMap用Adapter（エラーをシミュレート）
package WeatherAdapter::OpenWeatherMap {
    use v5.36;
    use Moo;
    use Try::Tiny;

    has name => (is => 'ro', default => 'OpenWeatherMap');
    has fail_cities => (is => 'ro', default => sub { [] });

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        # 特定の都市でエラーをシミュレート
        if (grep { $_ eq $city } $self->fail_cities->@*) {
            die "API connection timeout for $city";
        }

        my %mock_data = (
            'Tokyo'   => { name => 'Tokyo',   main => { temp => 25.5, humidity => 60 }, weather => [{ description => '晴れ' }] },
            'Osaka'   => { name => 'Osaka',   main => { temp => 27.2, humidity => 65 }, weather => [{ description => '曇り' }] },
            'Nagoya'  => { name => 'Nagoya',  main => { temp => 26.8, humidity => 62 }, weather => [{ description => '晴れ' }] },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        try {
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
        catch {
            warn "[$self->{name}] $city: $_";
            return;
        };
    }
}

# WeatherStack用Adapter（エラーをシミュレート）
package WeatherAdapter::WeatherStack {
    use v5.36;
    use Moo;
    use Try::Tiny;

    has name => (is => 'ro', default => 'WeatherStack');
    has fail_cities => (is => 'ro', default => sub { [] });

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        # 特定の都市でエラーをシミュレート
        if (grep { $_ eq $city } $self->fail_cities->@*) {
            die "API rate limit exceeded for $city";
        }

        my %mock_data = (
            'Tokyo'   => { location => { name => 'Tokyo' },   current => { temperature => 26, humidity => 58, weather_descriptions => ['Sunny'] } },
            'Sapporo' => { location => { name => 'Sapporo' }, current => { temperature => 19, humidity => 68, weather_descriptions => ['Rain'] } },
            'Sendai'  => { location => { name => 'Sendai' },  current => { temperature => 22, humidity => 65, weather_descriptions => ['Cloudy'] } },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        try {
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
        catch {
            warn "[$self->{name}] $city: $_";
            return;
        };
    }
}

# エラーハンドリング付きFacade
package WeatherFacade {
    use v5.36;
    use Moo;

    has adapters        => (is => 'ro', required => 1);
    has use_default     => (is => 'ro', default => 1);   # デフォルト値を使うか
    has default_message => (is => 'ro', default => '情報を取得できませんでした');

    # デフォルト天気データを生成
    sub _default_weather ($self, $city) {
        return {
            city        => $city,
            temperature => undef,
            humidity    => undef,
            condition   => $self->default_message,
            source      => 'default',
            is_default  => 1,
        };
    }

    # 天気情報を取得
    sub get_weather ($self, $city) {
        for my $adapter ($self->adapters->@*) {
            my $weather = $adapter->get_weather($city);
            if ($weather) {
                return { $weather->%*, is_default => 0 };
            }
        }

        # すべて失敗した場合
        if ($self->use_default) {
            return $self->_default_weather($city);
        }
        return;
    }

    # 複数都市の天気を一括取得
    sub get_weather_bulk ($self, @cities) {
        my @results;
        for my $city (@cities) {
            push @results, $self->get_weather($city);
        }
        return @results;
    }
}

# メイン処理
package main {
    use v5.36;

    say "=== 天気予報アグリゲーター（エラーハンドリング版） ===";
    say "";

    # 両方のAPIで「Fukuoka」がエラーになるように設定
    my $facade = WeatherFacade->new(
        adapters => [
            WeatherAdapter::OpenWeatherMap->new(fail_cities => ['Fukuoka']),
            WeatherAdapter::WeatherStack->new(fail_cities => ['Fukuoka']),
        ],
        use_default => 1,
    );

    say "--- 天気情報取得 ---";
    say "";

    my @cities = qw(Tokyo Osaka Sapporo Fukuoka);

    for my $city (@cities) {
        my $weather = $facade->get_weather($city);

        # 常に有効なデータ構造が返る
        my $temp = $weather->{temperature} // '---';
        my $status = $weather->{is_default} ? '[デフォルト]' : "[via $weather->{source}]";

        say "$weather->{city}: $weather->{condition}（気温: $temp℃）$status";
    }

    say "";
    say "--- デフォルト値を使わない場合 ---";

    my $facade_strict = WeatherFacade->new(
        adapters => [
            WeatherAdapter::OpenWeatherMap->new(fail_cities => ['Fukuoka']),
            WeatherAdapter::WeatherStack->new(fail_cities => ['Fukuoka']),
        ],
        use_default => 0,  # デフォルト値を使わない
    );

    my $result = $facade_strict->get_weather('Fukuoka');
    if ($result) {
        say "Fukuoka: $result->{condition}";
    }
    else {
        say "Fukuoka: データ取得に失敗しました（undefが返されました）";
    }
}
