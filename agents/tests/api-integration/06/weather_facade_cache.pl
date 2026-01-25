#!/usr/bin/env perl
use v5.36;

# 天気サービスの共通インターフェース（Role）
package WeatherAdapter::Role {
    use v5.36;
    use Moo::Role;

    requires 'get_weather';
    requires 'name';
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

# キャッシュ付きFacade
package WeatherFacade {
    use v5.36;
    use Moo;

    has adapters   => (is => 'ro', required => 1);
    has cache_ttl  => (is => 'ro', default => 300);   # 5分
    has max_size   => (is => 'ro', default => 100);   # 最大100エントリ
    has _cache     => (is => 'ro', default => sub { {} });
    has _cache_order => (is => 'ro', default => sub { [] });  # LRU順序管理
    has _stats     => (is => 'ro', default => sub { { hits => 0, misses => 0 } });

    # キャッシュから取得（LRU更新）
    sub _get_from_cache ($self, $city) {
        return unless exists $self->_cache->{$city};

        my $cached = $self->_cache->{$city};
        my $age = time() - $cached->{cached_at};

        if ($age >= $self->cache_ttl) {
            # 期限切れ
            $self->_remove_from_cache($city);
            return;
        }

        # LRU順序を更新（最近使用したものを末尾に）
        $self->_cache_order->@* = grep { $_ ne $city } $self->_cache_order->@*;
        push $self->_cache_order->@*, $city;

        return $cached->{data};
    }

    # キャッシュに保存
    sub _set_to_cache ($self, $city, $data) {
        # サイズ上限チェック
        while (scalar($self->_cache_order->@*) >= $self->max_size) {
            my $oldest = shift $self->_cache_order->@*;
            delete $self->_cache->{$oldest};
        }

        $self->_cache->{$city} = {
            data      => $data,
            cached_at => time(),
        };
        push $self->_cache_order->@*, $city;
    }

    # キャッシュから削除
    sub _remove_from_cache ($self, $city) {
        delete $self->_cache->{$city};
        $self->_cache_order->@* = grep { $_ ne $city } $self->_cache_order->@*;
    }

    # 天気情報を取得
    sub get_weather ($self, $city) {
        # キャッシュチェック
        if (my $cached = $self->_get_from_cache($city)) {
            $self->_stats->{hits}++;
            return { $cached->%*, from_cache => 1 };
        }

        $self->_stats->{misses}++;

        # APIから取得
        for my $adapter ($self->adapters->@*) {
            my $weather = $adapter->get_weather($city);
            if ($weather) {
                $self->_set_to_cache($city, $weather);
                return { $weather->%*, from_cache => 0 };
            }
        }
        return;
    }

    # キャッシュ統計
    sub cache_stats ($self) {
        my $total = $self->_stats->{hits} + $self->_stats->{misses};
        my $hit_rate = $total > 0 ? ($self->_stats->{hits} / $total * 100) : 0;
        return {
            hits     => $self->_stats->{hits},
            misses   => $self->_stats->{misses},
            hit_rate => sprintf("%.1f%%", $hit_rate),
            size     => scalar($self->_cache_order->@*),
        };
    }

    # キャッシュクリア
    sub clear_cache ($self) {
        $self->_cache->%* = ();
        $self->_cache_order->@* = ();
    }
}

# メイン処理
package main {
    use v5.36;

    say "=== 天気予報アグリゲーター（キャッシュ付き） ===";
    say "";

    my $facade = WeatherFacade->new(
        adapters  => [
            WeatherAdapter::OpenWeatherMap->new,
            WeatherAdapter::WeatherStack->new,
        ],
        cache_ttl => 300,  # 5分
        max_size  => 10,   # デモ用に小さく
    );

    # 同じ都市を複数回取得
    say "--- 1回目の取得（キャッシュなし） ---";
    for my $city (qw(Tokyo Osaka Sapporo)) {
        my $weather = $facade->get_weather($city);
        if ($weather) {
            my $cache_status = $weather->{from_cache} ? "キャッシュから" : "APIから";
            say "$city: $weather->{condition}（$cache_status）";
        }
    }

    say "";
    say "--- 2回目の取得（キャッシュあり） ---";
    for my $city (qw(Tokyo Osaka Sapporo)) {
        my $weather = $facade->get_weather($city);
        if ($weather) {
            my $cache_status = $weather->{from_cache} ? "キャッシュから" : "APIから";
            say "$city: $weather->{condition}（$cache_status）";
        }
    }

    say "";
    say "--- キャッシュ統計 ---";
    my $stats = $facade->cache_stats;
    say "ヒット数: $stats->{hits}";
    say "ミス数: $stats->{misses}";
    say "ヒット率: $stats->{hit_rate}";
    say "キャッシュサイズ: $stats->{size}";
}
